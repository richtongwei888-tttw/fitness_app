import os
import json
from json import JSONDecodeError
from datetime import date

from kivy.app import App
from kivy.core.text import LabelBase
from kivy.core.window import Window

from kivy.uix.screenmanager import ScreenManager, Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.textinput import TextInput
from kivy.uix.button import Button
from kivy.uix.scrollview import ScrollView
from kivy.uix.modalview import ModalView
from kivy.clock import Clock

from kivy.graphics import Color, Rectangle, RoundedRectangle
from functools import partial

# 注册字体（Windows）
LabelBase.register(name='ChineseFont', fn_regular='C:/Windows/Fonts/msyh.ttc')
FONT = "ChineseFont"

# 手机比例窗口
Window.size = (390, 780)
Window.clearcolor = (0.95, 0.95, 0.97, 1)

PRIMARY = (0.12, 0.45, 0.90, 1)
BG = (0.95, 0.95, 0.97, 1)
CARD_BG = (1, 1, 1, 1)
TEXT = (0.12, 0.12, 0.14, 1)
MUTED = (0.35, 0.35, 0.38, 1)
DANGER = (0.86, 0.24, 0.24, 1)
SUCCESS = (0.18, 0.72, 0.38, 1)
FIELD_BG = (0.97, 0.97, 0.99, 1)

ERR_MSG = "不要使坏，正确填写吧"


def apply_bg_rect(widget, color_rgba):
    with widget.canvas.before:
        Color(*color_rgba)
        rect = Rectangle(pos=widget.pos, size=widget.size)

    def _upd(*_):
        rect.pos = widget.pos
        rect.size = widget.size

    widget.bind(pos=_upd, size=_upd)
    return rect


class Card(BoxLayout):
    def __init__(self, radius=16, bg=CARD_BG, **kwargs):
        super().__init__(**kwargs)
        with self.canvas.before:
            Color(*bg)
            self._rr = RoundedRectangle(pos=self.pos, size=self.size, radius=[radius])
        self.bind(pos=self._upd, size=self._upd)

    def _upd(self, *_):
        self._rr.pos = self.pos
        self._rr.size = self.size


def make_flat_button(text, bg_color, text_color=(1, 1, 1, 1), height=50, font_size=18):
    return Button(
        text=text,
        font_name=FONT,
        font_size=font_size,
        size_hint_y=None,
        height=height,
        background_normal="",
        background_down="",
        background_color=bg_color,
        color=text_color,
    )


def make_text_input(width=None, font_size=16, max_len=4, int_only=False):
    ti = TextInput(
        multiline=False,
        font_name=FONT,
        font_size=font_size,
        padding=[10, 10, 10, 10],
        background_normal="",
        background_active="",
        background_color=FIELD_BG,
        foreground_color=TEXT,
        cursor_color=TEXT,
        size_hint_x=None if width else 1,
        width=width if width else 0,
    )
    if int_only:
        ti.input_filter = "int"

    def _limit(_, val):
        if max_len and len(val) > max_len:
            ti.text = val[:max_len]

    ti.bind(text=_limit)
    return ti


class MsgPopup(ModalView):
    def __init__(self, msg: str, **kwargs):
        super().__init__(**kwargs)
        self.size_hint = (0.88, None)
        self.height = 170
        self.auto_dismiss = True

        body = Card(orientation="vertical", padding=16, spacing=12, radius=18, size_hint=(1, 1))
        lab = Label(
            text=msg,
            font_name=FONT,
            font_size=18,
            color=TEXT,
            halign="center",
            valign="middle",
        )
        lab.bind(size=lambda inst, val: setattr(inst, "text_size", val))
        ok = make_flat_button("知道了", bg_color=PRIMARY, height=48, font_size=18)
        ok.bind(on_press=lambda *_: self.dismiss())

        body.add_widget(lab)
        body.add_widget(ok)
        self.add_widget(body)


class ChoicePopup(ModalView):
    def __init__(self, title_text: str, options: list[str], on_pick, **kwargs):
        super().__init__(**kwargs)
        self.size_hint = (0.90, 0.62)
        self.auto_dismiss = True

        body = Card(orientation="vertical", padding=16, spacing=12, radius=18)

        title = Label(
            text=title_text,
            font_name=FONT,
            font_size=20,
            color=PRIMARY,
            size_hint_y=None,
            height=30,
            halign="center",
            valign="middle",
        )
        title.bind(size=lambda inst, val: setattr(inst, "text_size", val))
        body.add_widget(title)

        box = BoxLayout(orientation="vertical", spacing=10, size_hint_y=None)
        box.bind(minimum_height=box.setter("height"))

        for opt in options:
            b = make_flat_button(
                opt,
                bg_color=(0.92, 0.94, 0.98, 1),
                text_color=TEXT,
                height=48,
                font_size=18,
            )
            b.bind(on_press=lambda inst, v=opt: self._pick(v, on_pick))
            box.add_widget(b)

        scroll = ScrollView(do_scroll_x=False)
        scroll.add_widget(box)
        body.add_widget(scroll)

        cancel = make_flat_button("取消", bg_color=(0.75, 0.75, 0.78, 1), text_color=TEXT, height=48, font_size=18)
        cancel.bind(on_press=lambda *_: self.dismiss())
        body.add_widget(cancel)

        self.add_widget(body)

    def _pick(self, value, on_pick):
        on_pick(value)
        self.dismiss()


class InputScreen(Screen):
    def __init__(self, app, **kwargs):
        super().__init__(**kwargs)
        self.app = app

        root = BoxLayout(orientation="vertical")
        apply_bg_rect(root, BG)

        # AppBar
        appbar = BoxLayout(orientation="horizontal", size_hint_y=None, height=56, padding=[16, 0, 16, 0])
        apply_bg_rect(appbar, PRIMARY)
        appbar.add_widget(Label(text="健身记录", font_name=FONT, font_size=20, color=(1, 1, 1, 1)))
        root.add_widget(appbar)

        scroll = ScrollView(do_scroll_x=False)
        content = BoxLayout(orientation="vertical", padding=[16, 16], spacing=12, size_hint_y=None)
        content.bind(minimum_height=content.setter("height"))
        scroll.add_widget(content)
        root.add_widget(scroll)

        self.form_card = Card(orientation="vertical", padding=14, spacing=10, radius=18, size_hint_y=None)
        self.form_card.bind(minimum_height=self.form_card.setter("height"))
        content.add_widget(self.form_card)

        # 时间：2026年xx月xx日（保证“日”不溢出）
        self.year = date.today().year
        time_row = BoxLayout(orientation="horizontal", spacing=6, size_hint_y=None, height=42)

        lab_time = Label(
            text=f"时间：{self.year}年",
            font_name=FONT,
            font_size=16,
            color=TEXT,
            size_hint_x=None,
            width=122,
            halign="right",
            valign="middle",
        )
        lab_time.bind(size=lambda inst, val: setattr(inst, "text_size", val))

        self.month_input = make_text_input(width=60, font_size=16, max_len=2, int_only=True)
        lab_m = Label(text="月", font_name=FONT, font_size=16, color=MUTED, size_hint_x=None, width=18)

        self.day_input = make_text_input(width=60, font_size=16, max_len=2, int_only=True)
        lab_d = Label(text="日", font_name=FONT, font_size=16, color=MUTED, size_hint_x=None, width=18)

        time_row.add_widget(lab_time)
        time_row.add_widget(self.month_input)
        time_row.add_widget(lab_m)
        time_row.add_widget(self.day_input)
        time_row.add_widget(lab_d)
        self.form_card.add_widget(time_row)

        # 选择行
        self.part_value = "未选择"
        self.part_btn = self._make_select_row("训练部位", self.part_value, self.open_part_picker)

        self.quality_value = "未选择"
        self.quality_btn = self._make_select_row("训练质量", self.quality_value, self.open_quality_picker)

        self.aerobic_value = "没做"
        self.aerobic_btn = self._make_select_row("是否有氧", self.aerobic_value, self.open_aerobic_picker)

        # 有氧分钟行（默认不显示）
        self.minutes_row = BoxLayout(orientation="horizontal", spacing=8, size_hint_y=None, height=42)
        lab_min = Label(
            text="有氧时间",
            font_name=FONT,
            font_size=16,
            color=TEXT,
            size_hint_x=None,
            width=140,
            halign="right",
            valign="middle",
        )
        lab_min.bind(size=lambda inst, val: setattr(inst, "text_size", val))

        self.aerobic_minutes_input = make_text_input(width=120, font_size=16, max_len=4, int_only=True)
        lab_min_unit = Label(text="分钟", font_name=FONT, font_size=16, color=MUTED, size_hint_x=None, width=44)

        self.minutes_row.add_widget(lab_min)
        self.minutes_row.add_widget(self.aerobic_minutes_input)
        self.minutes_row.add_widget(lab_min_unit)

        # 底部按钮区
        btn_area = BoxLayout(orientation="vertical", padding=[16, 10], spacing=10, size_hint_y=None, height=130)
        apply_bg_rect(btn_area, BG)

        add_btn = make_flat_button("添加记录", bg_color=SUCCESS, height=52, font_size=19)
        add_btn.bind(on_press=self.add_record)

        view_btn = make_flat_button("查看记录", bg_color=(0.90, 0.55, 0.12, 1), height=48, font_size=18)
        view_btn.bind(on_press=lambda *_: setattr(self.manager, "current", "records"))

        btn_area.add_widget(add_btn)
        btn_area.add_widget(view_btn)
        root.add_widget(btn_area)

        self.add_widget(root)

    def _make_select_row(self, label_text, default_value, on_press):
        row = BoxLayout(orientation="horizontal", spacing=8, size_hint_y=None, height=42)

        lab = Label(
            text=label_text,
            font_name=FONT,
            font_size=16,
            color=TEXT,
            size_hint_x=None,
            width=140,
            halign="right",
            valign="middle",
        )
        lab.bind(size=lambda inst, val: setattr(inst, "text_size", val))

        btn = make_flat_button(
            default_value,
            bg_color=(0.92, 0.94, 0.98, 1),
            text_color=TEXT,
            height=42,
            font_size=16,
        )
        btn.size_hint_x = 1
        btn.bind(on_press=on_press)

        row.add_widget(lab)
        row.add_widget(btn)
        self.form_card.add_widget(row)
        return btn

    # 选择弹窗
    def open_part_picker(self, *_):
        ChoicePopup("选择训练部位", ["胸", "背", "肩", "腿"], on_pick=self.set_part).open()

    def set_part(self, v):
        self.part_value = v
        self.part_btn.text = v

    def open_quality_picker(self, *_):
        ChoicePopup("选择训练质量", ["好", "一般", "差"], on_pick=self.set_quality).open()

    def set_quality(self, v):
        self.quality_value = v
        self.quality_btn.text = v

    def open_aerobic_picker(self, *_):
        ChoicePopup("是否做有氧", ["没做", "做了"], on_pick=self.set_aerobic).open()

    def set_aerobic(self, v):
        self.aerobic_value = v
        self.aerobic_btn.text = v

        if v == "做了":
            if self.minutes_row.parent is None:
                self.form_card.add_widget(self.minutes_row)
        else:
            self.aerobic_minutes_input.text = ""
            if self.minutes_row.parent is not None:
                self.form_card.remove_widget(self.minutes_row)

    def _bad_input(self, focus_widget=None, clear_date=False, clear_minutes=False):
        if clear_date:
            self.month_input.text = ""
            self.day_input.text = ""
        if clear_minutes:
            self.aerobic_minutes_input.text = ""

        pop = MsgPopup(ERR_MSG)
        if focus_widget is not None:
            pop.bind(on_dismiss=lambda *_: setattr(focus_widget, "focus", True))
        pop.open()

    def add_record(self, *_):
        m_txt = self.month_input.text.strip()
        d_txt = self.day_input.text.strip()

        if (not m_txt) or (not d_txt) or (not m_txt.isdigit()) or (not d_txt.isdigit()):
            self._bad_input(focus_widget=self.month_input, clear_date=True)
            return

        m = int(m_txt)
        d = int(d_txt)

        if not (1 <= m <= 12) or not (1 <= d <= 31):
            self._bad_input(focus_widget=self.month_input, clear_date=True)
            return

        try:
            _ = date(self.year, m, d)
        except Exception:
            self._bad_input(focus_widget=self.month_input, clear_date=True)
            return

        if self.part_value == "未选择" or self.quality_value == "未选择":
            MsgPopup("请先选择训练部位和训练质量").open()
            return

        mins_val = None
        if self.aerobic_value == "做了":
            mins_txt = self.aerobic_minutes_input.text.strip()
            if (not mins_txt) or (not mins_txt.isdigit()):
                self._bad_input(focus_widget=self.aerobic_minutes_input, clear_minutes=True)
                return
            mins_val = int(mins_txt)

        date_std = f"{self.year}-{m:02d}-{d:02d}"
        record = {
            "date": date_std,
            "part": self.part_value,
            "quality": self.quality_value,
            "aerobic_done": self.aerobic_value,
            "aerobic_minutes": mins_val
        }

        self.app.records.append(record)
        self.app.save_records()

        self.month_input.text = ""
        self.day_input.text = ""
        self.set_part("未选择")
        self.set_quality("未选择")
        self.set_aerobic("没做")

        MsgPopup("记录添加成功！").open()


class RecordsScreen(Screen):
    def __init__(self, app, **kwargs):
        super().__init__(**kwargs)
        self.app = app

        root = BoxLayout(orientation="vertical")
        apply_bg_rect(root, BG)

        # AppBar
        appbar = BoxLayout(orientation="horizontal", size_hint_y=None, height=56, padding=[12, 0, 12, 0], spacing=8)
        apply_bg_rect(appbar, PRIMARY)

        back_btn = make_flat_button("←", bg_color=PRIMARY, height=56, font_size=22)
        back_btn.size_hint_x = None
        back_btn.width = 56
        back_btn.bind(on_press=lambda *_: setattr(self.manager, "current", "input"))

        # AppBar 标题居中：左侧加一个等宽占位，让“记录”真正居中
        title = Label(
            text="记录",
            font_name=FONT,
            font_size=20,
            color=(1, 1, 1, 1),
            halign="center",
            valign="middle",
        )
        title.bind(size=lambda inst, val: setattr(inst, "text_size", val))

        right_spacer = Label(size_hint_x=None, width=back_btn.width)  # 右侧占位，和返回按钮等宽

        appbar.add_widget(back_btn)
        appbar.add_widget(title)
        appbar.add_widget(right_spacer)
        root.add_widget(appbar)

        scroll = ScrollView(do_scroll_x=False)
        self.list_box = BoxLayout(orientation="vertical", padding=[16, 16], spacing=10, size_hint_y=None)
        self.list_box.bind(minimum_height=self.list_box.setter("height"))
        scroll.add_widget(self.list_box)
        root.add_widget(scroll)

        self.add_widget(root)

    def on_pre_enter(self, *args):
        self.update_records()

    def _format_record(self, r):
        if isinstance(r, str):
            # 旧字符串尽量不崩（也去掉前后空白）
            s = r.strip()
            lines = [ln.strip() for ln in s.splitlines() if ln.strip()]
            return "\n".join(lines) if lines else s

        d = str(r.get("date", "")).strip()
        part = str(r.get("part", "")).strip()
        q = str(r.get("quality", "")).strip()
        done = str(r.get("aerobic_done", "没做")).strip()
        mins = r.get("aerobic_minutes", None)

        d_cn = d
        try:
            yy, mm, dd = d.split("-")
            mm = f"{int(mm):02d}"
            dd = f"{int(dd):02d}"
            d_cn = f"{yy}年{mm}月{dd}日"
        except Exception:
            pass

        if done == "做了":
            aerobic = f"有氧：做了（{mins}分钟）" if mins is not None else "有氧：做了"
        else:
            aerobic = "有氧：没做"

        return f"{d_cn}\n部位：{part}｜质量：{q}\n{aerobic}"

    # ✅ 关键修复：每条记录都独立 reflow，不再“只有最后一条正常”
    def _reflow_item(self, label: Label, *args, item=None):
        if item is None:
            return
        label.text_size = (label.width, None)
        label.height = label.texture_size[1] + 6
        item.height = max(92, label.height + 24)

    def update_records(self):
        self.list_box.clear_widgets()
        records = list(self.app.records)[::-1]

        if not records:
            empty = Label(text="暂无记录", font_name=FONT, font_size=16, color=MUTED, size_hint_y=None, height=40)
            self.list_box.add_widget(empty)
            return

        for visual_idx, r in enumerate(records):
            real_index = len(self.app.records) - 1 - visual_idx

            item = Card(orientation="horizontal", padding=[12, 12], spacing=10, radius=18, size_hint_y=None)
            item.height = 92

            lab = Label(
                text=self._format_record(r),
                font_name=FONT,
                font_size=15,
                color=TEXT,
                halign="left",
                valign="top",
                size_hint_x=1,
                size_hint_y=None,
            )

            del_btn = make_flat_button("删除", bg_color=DANGER, height=44, font_size=16)
            del_btn.size_hint_x = None
            del_btn.width = 72
            del_btn.bind(on_press=partial(self.delete_record, real_index))

            # ✅ 绑定时把 item 固定住（不再闭包错绑到最后一条）
            lab.bind(width=partial(self._reflow_item, item=item))
            lab.bind(texture_size=partial(self._reflow_item, item=item))

            item.add_widget(lab)
            item.add_widget(del_btn)
            self.list_box.add_widget(item)

            # ✅ 每条都单独 schedule（固定 lab/item）
            Clock.schedule_once(lambda dt, l=lab, it=item: self._reflow_item(l, item=it), 0)

    def delete_record(self, real_index, *_):
        try:
            del self.app.records[real_index]
            self.app.save_records()
            self.update_records()
            MsgPopup("记录删除成功！").open()
        except Exception:
            MsgPopup("删除失败").open()


class FitnessApp(App):
    @property
    def records_path(self) -> str:
        return os.path.join(self.user_data_dir, "records.json")

    def build(self):
        self.records = self.load_records()
        sm = ScreenManager()
        sm.add_widget(InputScreen(app=self, name="input"))
        sm.add_widget(RecordsScreen(app=self, name="records"))
        return sm

    def save_records(self):
        os.makedirs(self.user_data_dir, exist_ok=True)
        with open(self.records_path, "w", encoding="utf-8") as f:
            json.dump(self.records, f, ensure_ascii=False, indent=2)

    def load_records(self):
        legacy_path = os.path.join(os.getcwd(), "records.json")

        def _load(path):
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
                return data if isinstance(data, list) else []

        try:
            if os.path.exists(self.records_path):
                return _load(self.records_path)

            if os.path.exists(legacy_path):
                data = _load(legacy_path)
                os.makedirs(self.user_data_dir, exist_ok=True)
                with open(self.records_path, "w", encoding="utf-8") as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)
                return data

            return []
        except (FileNotFoundError, JSONDecodeError):
            return []
        except Exception:
            return []


if __name__ == "__main__":
    FitnessApp().run()