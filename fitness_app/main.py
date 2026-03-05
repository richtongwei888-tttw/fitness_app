# -*- coding: utf-8 -*-
"""
Kivy 健身记录 App（桌面/安卓）
- 主页：填写记录 + “今天是有氧日”滑动开关
- 记录页：查看/删除历史记录
- 底部导航栏：主页 / 记录

说明：为了避免 Android 字体文件缺失导致闪退，本文件默认使用系统/内置字体，
如果项目目录里存在 msyh.ttc 会自动使用它（可选）。
"""

import json
import os
from datetime import datetime
from pathlib import Path

from kivy.app import App
from kivy.clock import Clock
from kivy.core.text import LabelBase
from kivy.metrics import dp
from kivy.properties import BooleanProperty, StringProperty, NumericProperty
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.gridlayout import GridLayout
from kivy.uix.label import Label
from kivy.uix.popup import Popup
from kivy.uix.screenmanager import Screen, ScreenManager, FadeTransition
from kivy.uix.scrollview import ScrollView
from kivy.uix.switch import Switch
from kivy.uix.textinput import TextInput
from kivy.uix.widget import Widget

from kivy.graphics import Color, Rectangle, RoundedRectangle, Line


# ----------------------------
# 颜色 & 字体（可按需微调）
# ----------------------------
WHITE = (1, 1, 1, 1)
BLACK = (0, 0, 0, 1)
MUTED_TEXT = (0.15, 0.15, 0.15, 1)
SUBTLE = (0.65, 0.65, 0.65, 1)

# 有氧日淡蓝色（整个界面）
CARDIO_BG = (0.86, 0.93, 1.00, 1)

# 统一主色（按钮/高亮）
ACCENT = (0.12, 0.53, 0.96, 1)

# 表单“卡片”背景（白底上更柔和一点点）
CARD_BG_NORMAL = (0.97, 0.98, 0.99, 1)
CARD_BG_CARDIO = (0.93, 0.97, 1.00, 1)

BORDER = (0.15, 0.15, 0.15, 1)


def try_register_font():
    """
    可选字体注册（安全版）：
    - 如果项目中带了 msyh.ttc / msyh.ttf 等字体，只有在“能被 Kivy/Sdl2 真正加载”时才启用。
    - 否则一律回退到系统默认字体，避免 Android 上因为字体文件不可用导致秒闪退。
    """
    from kivy.core.text import Label as CoreLabel

    candidates = [
        Path(__file__).resolve().parent / "msyh.ttc",
        Path(__file__).resolve().parent / "msyh.ttf",
        Path(__file__).resolve().parent / "msyh.otf",
        Path(os.getcwd()) / "msyh.ttc",
        Path(os.getcwd()) / "msyh.ttf",
        Path(os.getcwd()) / "msyh.otf",
    ]

    for fp in candidates:
        if not fp.exists():
            continue
        try:
            # 关键：先做一次真实渲染测试，能 refresh 才说明字体可用
            test = CoreLabel(text="测试Test", font_name=str(fp), font_size=12)
            test.refresh()
            LabelBase.register(name="AppFont", fn_regular=str(fp))
            return "AppFont"
        except Exception:
            # 字体不可用就跳过，绝不硬用
            continue

    return ""



APP_FONT_NAME = try_register_font() or "Roboto"


def load_records(records_path: Path):
    if not records_path.exists():
        return []
    try:
        return json.loads(records_path.read_text(encoding="utf-8"))
    except Exception:
        return []


def save_records(records_path: Path, records):
    records_path.parent.mkdir(parents=True, exist_ok=True)
    records_path.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")


class Separator(Widget):
    """一条黑色分割线（上/下隔开用）"""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.size_hint_y = None
        self.height = dp(1)
        with self.canvas:
            Color(*BLACK)
            self._rect = Rectangle(pos=self.pos, size=self.size)
        self.bind(pos=self._update, size=self._update)

    def _update(self, *_):
        self._rect.pos = self.pos
        self._rect.size = self.size


class SoftCard(BoxLayout):
    """柔和的内容卡片：圆角 + 细边框，避免白底上突兀。"""
    bg_rgba = (0.97, 0.98, 0.99, 1)
    radius = NumericProperty(dp(16))

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.orientation = "vertical"
        self.padding = dp(14)
        self.spacing = dp(10)
        self.size_hint_y = None

        with self.canvas.before:
            self._bg_color = Color(*self.bg_rgba)
            self._bg = RoundedRectangle(pos=self.pos, size=self.size, radius=[self.radius])
            Color(*BORDER)
            self._border = Line(rounded_rectangle=(self.x, self.y, self.width, self.height, self.radius), width=1.0)

        self.bind(pos=self._update_canvas, size=self._update_canvas)

    def set_bg(self, rgba):
        self._bg_color.rgba = rgba

    def _update_canvas(self, *_):
        self._bg.pos = self.pos
        self._bg.size = self.size
        self._bg.radius = [self.radius]
        self._border.rounded_rectangle = (self.x, self.y, self.width, self.height, self.radius)


def make_title(text):
    return Label(
        text=text,
        font_name=APP_FONT_NAME if APP_FONT_NAME else None,
        color=BLACK,
        bold=True,
        font_size=dp(18),
        size_hint_y=None,
        height=dp(48),
        halign="left",
        valign="middle",
        padding=(dp(14), 0),
    )


def make_label(text):
    return Label(
        text=text,
        font_name=APP_FONT_NAME if APP_FONT_NAME else None,
        color=MUTED_TEXT,
        font_size=dp(16),
        size_hint_x=0.45,
        halign="left",
        valign="middle",
    )


def make_value_button(text, on_press=None):
    btn = Button(
        text=text,
        font_name=APP_FONT_NAME if APP_FONT_NAME else None,
        font_size=dp(16),
        color=BLACK,
        background_normal="",
        background_color=WHITE,
        size_hint_x=0.55,
    )
    # 细边框让按钮更像输入框
    with btn.canvas.before:
        Color(0.80, 0.80, 0.80, 1)
        btn._border = Line(rounded_rectangle=(btn.x, btn.y, btn.width, btn.height, dp(10)), width=1.0)
    def _update(*_):
        btn._border.rounded_rectangle = (btn.x, btn.y, btn.width, btn.height, dp(10))
    btn.bind(pos=_update, size=_update)

    if on_press:
        btn.bind(on_press=on_press)
    return btn


def make_primary_button(text, on_press):
    btn = Button(
        text=text,
        font_name=APP_FONT_NAME if APP_FONT_NAME else None,
        font_size=dp(18),
        bold=True,
        color=WHITE,
        background_normal="",
        background_color=ACCENT,
        size_hint_y=None,
        height=dp(52),
    )
    btn.bind(on_press=on_press)
    # 圆角
    with btn.canvas.before:
        Color(0, 0, 0, 0)  # 占位（避免某些机型 canvas 顺序问题）
        btn._bg = RoundedRectangle(pos=btn.pos, size=btn.size, radius=[dp(14)])
    def _sync(*_):
        btn._bg.pos = btn.pos
        btn._bg.size = btn.size
    btn.bind(pos=_sync, size=_sync)
    return btn


class InputScreen(Screen):
    cardio_mode = BooleanProperty(False)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.app = App.get_running_app()
        self.records_path = Path(self.app.user_data_dir) / "records.json"

        self.root_layout = BoxLayout(orientation="vertical", spacing=0)

        # --- 顶部 AppBar（白底 + 黑线）
        self.appbar = BoxLayout(orientation="vertical", size_hint_y=None, height=dp(56))
        self.appbar_bg = self._apply_solid_bg(self.appbar, WHITE)
        self.appbar.add_widget(
            Label(
                text="健身记录",
                font_name=APP_FONT_NAME if APP_FONT_NAME else None,
                color=BLACK,
                bold=True,
                font_size=dp(20),
            )
        )
        self.root_layout.add_widget(self.appbar)
        self.root_layout.add_widget(Separator())

        # --- 内容区（可滚动）
        self.body = BoxLayout(orientation="vertical", padding=(dp(16), dp(16)), spacing=dp(12))
        self.body_bg = self._apply_solid_bg(self.body, WHITE)

        self.card = SoftCard()
        self.card.set_bg(CARD_BG_NORMAL)

        # 日期
        date_row = BoxLayout(size_hint_y=None, height=dp(56), spacing=dp(10))
        date_row.add_widget(make_label("日期"))
        self.date_input = TextInput(
            hint_text="YYYY-MM-DD",
            multiline=False,
            font_name=APP_FONT_NAME if APP_FONT_NAME else None,
            font_size=dp(16),
            foreground_color=BLACK,
            background_color=WHITE,
            cursor_color=BLACK,
        )
        date_row.add_widget(self.date_input)
        self.card.add_widget(date_row)

        # 锻炼部位
        self.part_row = BoxLayout(size_hint_y=None, height=dp(56), spacing=dp(10))
        self.part_row.add_widget(make_label("锻炼部位"))
        self.part_btn = make_value_button("未选择", self.open_part_picker)
        self.part_row.add_widget(self.part_btn)
        self.card.add_widget(self.part_row)

        # 强度/质量
        self.quality_row = BoxLayout(size_hint_y=None, height=dp(56), spacing=dp(10))
        self.quality_row.add_widget(make_label("强度"))
        self.quality_btn = make_value_button("未选择", self.open_quality_picker)
        self.quality_row.add_widget(self.quality_btn)
        self.card.add_widget(self.quality_row)

        # 是否有氧
        self.aerobic_row = BoxLayout(size_hint_y=None, height=dp(56), spacing=dp(10))
        self.aerobic_row.add_widget(make_label("是否有氧"))
        self.aerobic_btn = make_value_button("未选择", self.open_aerobic_picker)
        self.aerobic_row.add_widget(self.aerobic_btn)
        self.card.add_widget(self.aerobic_row)

        # 有氧时间（分钟）
        self.minutes_row = BoxLayout(size_hint_y=None, height=dp(56), spacing=dp(10))
        self.minutes_row.add_widget(make_label("有氧时间(分钟)"))
        self.minutes_input = TextInput(
            hint_text="例如 30",
            multiline=False,
            input_filter="int",
            font_name=APP_FONT_NAME if APP_FONT_NAME else None,
            font_size=dp(16),
            foreground_color=BLACK,
            background_color=WHITE,
            cursor_color=BLACK,
        )
        self.minutes_row.add_widget(self.minutes_input)
        self.minutes_row.opacity = 0
        self.minutes_row.disabled = True
        self.card.add_widget(self.minutes_row)

        # 有氧日开关（滑动 Switch）
        self.cardio_row = BoxLayout(size_hint_y=None, height=dp(56), spacing=dp(10))
        self.cardio_row.add_widget(make_label("今天是有氧日"))
        right = BoxLayout(orientation="horizontal", spacing=dp(10), size_hint_x=0.55)
        self.cardio_switch = Switch(active=False)
        self.cardio_switch.bind(active=self.on_cardio_toggle)
        right.add_widget(self.cardio_switch)
        right.add_widget(Label(
            text="开/关",
            font_name=APP_FONT_NAME if APP_FONT_NAME else None,
            color=SUBTLE,
            font_size=dp(14),
            size_hint_x=None,
            width=dp(50),
            halign="left",
            valign="middle",
        ))
        self.cardio_row.add_widget(right)
        self.card.add_widget(self.cardio_row)

        # 确定按钮（放在“有氧日”下面）
        self.confirm_btn = make_primary_button("确定", self.on_confirm)
        self.card.add_widget(self.confirm_btn)

        self.body.add_widget(self.card)

        # 填充，避免内容太靠上
        self.body.add_widget(Widget(size_hint_y=1))

        sv = ScrollView(do_scroll_x=False)
        sv.add_widget(self.body)
        self.root_layout.add_widget(sv)

        # --- 底部导航栏（白底 + 黑线）
        self.root_layout.add_widget(Separator())
        self.nav = self.build_nav(active="home")
        self.root_layout.add_widget(self.nav)

        self.add_widget(self.root_layout)

        # 卡片高度同步（让它看起来更像“中间一块内容区”）
        Clock.schedule_once(self._sync_card_height, 0)

    # ---------- UI helpers ----------
    def _apply_solid_bg(self, widget, rgba):
        with widget.canvas.before:
            c = Color(*rgba)
            r = Rectangle(pos=widget.pos, size=widget.size)
        def _u(*_):
            r.pos = widget.pos
            r.size = widget.size
        widget.bind(pos=_u, size=_u)
        return c  # 返回 Color 方便动态改色

    def build_nav(self, active="home"):
        nav = BoxLayout(orientation="horizontal", size_hint_y=None, height=dp(58), padding=(dp(10), 0), spacing=dp(10))
        nav_bg = self._apply_solid_bg(nav, WHITE)

        def make_nav_btn(title, key):
            btn = Button(
                text=title,
                font_name=APP_FONT_NAME if APP_FONT_NAME else None,
                font_size=dp(16),
                background_normal="",
                background_color=WHITE,
                color=ACCENT if key == active else BLACK,
            )
            def go(_):
                if key == "home":
                    self.manager.current = "input"
                else:
                    self.manager.current = "records"
            btn.bind(on_press=go)
            return btn

        nav.add_widget(make_nav_btn("主页", "home"))
        nav.add_widget(make_nav_btn("记录", "records"))
        # 存一下，便于后面需要更新高亮（可选）
        nav._bg = nav_bg
        return nav

    def _sync_card_height(self, *_):
        # 让卡片至少占 1/3 屏幕高度，但也不会太大
        min_h = self.height * 0.35
        content_h = sum((w.height if hasattr(w, "height") else 0) for w in self.card.children)
        # children 是倒序，height 都是固定的，这里只要给个下限即可
        self.card.height = max(min_h, dp(56) * 6 + dp(14) * 2 + dp(10) * 5)

    # ---------- Pickers ----------
    def _popup_picker(self, title, options, on_pick):
        gl = GridLayout(cols=1, spacing=dp(8), padding=dp(12), size_hint_y=None)
        gl.bind(minimum_height=gl.setter("height"))

        for opt in options:
            b = Button(
                text=opt,
                font_name=APP_FONT_NAME if APP_FONT_NAME else None,
                font_size=dp(16),
                color=BLACK,
                background_normal="",
                background_color=WHITE,
                size_hint_y=None,
                height=dp(48),
            )
            def _make_cb(v):
                def cb(_btn):
                    on_pick(v)
                    pop.dismiss()
                return cb
            b.bind(on_press=_make_cb(opt))
            gl.add_widget(b)

        sv = ScrollView(do_scroll_x=False)
        sv.add_widget(gl)

        pop = Popup(
            title=title,
            content=sv,
            size_hint=(0.85, 0.7),
            auto_dismiss=True,
        )
        pop.open()

    def open_part_picker(self, *_):
        if self.cardio_mode:
            return
        options = ["胸", "背", "腿", "肩", "手臂", "核心", "全身", "拉伸", "其他"]
        self._popup_picker("选择锻炼部位", options, self._set_part)

    def _set_part(self, v):
        self.part_btn.text = v

    def open_quality_picker(self, *_):
        if self.cardio_mode:
            return
        options = ["轻松", "正常", "困难", "力竭"]
        self._popup_picker("选择强度", options, self._set_quality)

    def _set_quality(self, v):
        self.quality_btn.text = v

    def open_aerobic_picker(self, *_):
        if self.cardio_mode:
            return
        options = ["做了", "没做"]
        self._popup_picker("是否有氧", options, self._set_aerobic)

    def _set_aerobic(self, v):
        self.aerobic_btn.text = v
        if v == "做了":
            self._show_minutes(True)
        else:
            self.minutes_input.text = ""
            self._show_minutes(False)

    def _show_minutes(self, show: bool):
        self.minutes_row.opacity = 1 if show else 0
        self.minutes_row.disabled = not show

    # ---------- Cardio mode toggle ----------
    def on_cardio_toggle(self, _sw, active: bool):
        self.cardio_mode = bool(active)

        if self.cardio_mode:
            # 进入有氧日：隐藏除日期+分钟外所有选项
            self.part_row.opacity = 0
            self.part_row.disabled = True
            self.quality_row.opacity = 0
            self.quality_row.disabled = True
            self.aerobic_row.opacity = 0
            self.aerobic_row.disabled = True

            # 强制显示分钟输入
            self._show_minutes(True)
            # 背景变淡蓝色（整个界面）
            self.body_bg.rgba = CARDIO_BG
            self.appbar_bg.rgba = CARDIO_BG
            self.card.set_bg(CARD_BG_CARDIO)

            # 自动把部位/有氧设置为有氧日（不强制写到按钮上也行，这里写上便于确认）
            self.part_btn.text = "今天是有氧日"
            self.quality_btn.text = "—"
            self.aerobic_btn.text = "做了"
        else:
            # 回到普通记录
            self.part_row.opacity = 1
            self.part_row.disabled = False
            self.quality_row.opacity = 1
            self.quality_row.disabled = False
            self.aerobic_row.opacity = 1
            self.aerobic_row.disabled = False

            # 背景回白
            self.body_bg.rgba = WHITE
            self.appbar_bg.rgba = WHITE
            self.card.set_bg(CARD_BG_NORMAL)

            # 根据是否有氧决定是否显示分钟
            if self.aerobic_btn.text == "做了":
                self._show_minutes(True)
            else:
                self._show_minutes(False)

            # 恢复按钮文案（不强行清空用户输入，只把“有氧日”占位清掉）
            if self.part_btn.text == "今天是有氧日":
                self.part_btn.text = "未选择"
            if self.quality_btn.text == "—":
                self.quality_btn.text = "未选择"
            if self.aerobic_btn.text == "做了":
                # 保留，不改
                pass

    # ---------- Save ----------
    def on_confirm(self, *_):
        date_str = self.date_input.text.strip()
        if not date_str:
            self._toast("请先填写日期")
            return

        # 简单校验日期格式（尽量不挡用户）
        try:
            datetime.strptime(date_str, "%Y-%m-%d")
        except Exception:
            self._toast("日期格式建议用 YYYY-MM-DD")
            # 不直接 return，让用户也能继续记录（你也可以改成 return）

        records = load_records(self.records_path)

        if self.cardio_mode:
            mins = self.minutes_input.text.strip()
            if not mins:
                self._toast("请填写有氧时间（分钟）")
                return
            record = {
                "date": date_str,
                "type": "cardio_day",
                "text": f"今天是有氧日，有氧时间：{mins}（分钟）",
                "minutes": int(mins) if mins.isdigit() else mins,
                "created_at": datetime.now().isoformat(timespec="seconds"),
            }
        else:
            part = self.part_btn.text.strip()
            quality = self.quality_btn.text.strip()
            aerobic = self.aerobic_btn.text.strip()

            if part in ("", "未选择") or quality in ("", "未选择") or aerobic in ("", "未选择"):
                self._toast("请把锻炼部位 / 强度 / 是否有氧 选完整")
                return

            mins = self.minutes_input.text.strip() if aerobic == "做了" else ""
            if aerobic == "做了" and not mins:
                self._toast("有氧选择了“做了”，请填写分钟数")
                return

            record = {
                "date": date_str,
                "type": "normal",
                "part": part,
                "quality": quality,
                "aerobic": aerobic,
                "minutes": int(mins) if mins.isdigit() else mins,
                "created_at": datetime.now().isoformat(timespec="seconds"),
            }

        records.append(record)
        save_records(self.records_path, records)

        # 提示语：用户要求改为这一句
        self._toast("今天又进步了，继续加油")

        # 轻量清空：日期保留由你决定；这里保留日期更方便连续记录
        if self.cardio_mode:
            self.minutes_input.text = ""
        else:
            self.part_btn.text = "未选择"
            self.quality_btn.text = "未选择"
            self.aerobic_btn.text = "未选择"
            self.minutes_input.text = ""
            self._show_minutes(False)

    def _toast(self, msg):
        content = Label(
            text=msg,
            font_name=APP_FONT_NAME if APP_FONT_NAME else None,
            color=BLACK,
        )
        pop = Popup(title="", content=content, size_hint=(0.75, 0.25), auto_dismiss=True)
        pop.open()
        Clock.schedule_once(lambda *_: pop.dismiss(), 1.0)


class RecordsScreen(Screen):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.app = App.get_running_app()
        self.records_path = Path(self.app.user_data_dir) / "records.json"

        self.root_layout = BoxLayout(orientation="vertical", spacing=0)

        # AppBar
        self.appbar = BoxLayout(orientation="vertical", size_hint_y=None, height=dp(56))
        self._apply_solid_bg(self.appbar, WHITE)
        self.appbar.add_widget(
            Label(
                text="记录",
                font_name=APP_FONT_NAME if APP_FONT_NAME else None,
                color=BLACK,
                bold=True,
                font_size=dp(20),
            )
        )
        self.root_layout.add_widget(self.appbar)
        self.root_layout.add_widget(Separator())

        # list container
        self.list_box = GridLayout(cols=1, spacing=dp(10), padding=(dp(16), dp(16)), size_hint_y=None)
        self.list_box.bind(minimum_height=self.list_box.setter("height"))

        sv = ScrollView(do_scroll_x=False)
        sv.add_widget(self.list_box)
        self.root_layout.add_widget(sv)

        # bottom nav
        self.root_layout.add_widget(Separator())
        self.nav = self.build_nav(active="records")
        self.root_layout.add_widget(self.nav)

        self.add_widget(self.root_layout)

        self.bind(on_pre_enter=lambda *_: self.refresh())

    def _apply_solid_bg(self, widget, rgba):
        with widget.canvas.before:
            Color(*rgba)
            r = Rectangle(pos=widget.pos, size=widget.size)
        def _u(*_):
            r.pos = widget.pos
            r.size = widget.size
        widget.bind(pos=_u, size=_u)

    def build_nav(self, active="records"):
        nav = BoxLayout(orientation="horizontal", size_hint_y=None, height=dp(58), padding=(dp(10), 0), spacing=dp(10))
        self._apply_solid_bg(nav, WHITE)

        def make_nav_btn(title, key):
            btn = Button(
                text=title,
                font_name=APP_FONT_NAME if APP_FONT_NAME else None,
                font_size=dp(16),
                background_normal="",
                background_color=WHITE,
                color=ACCENT if key == active else BLACK,
            )
            def go(_):
                if key == "home":
                    self.manager.current = "input"
                else:
                    self.manager.current = "records"
            btn.bind(on_press=go)
            return btn

        nav.add_widget(make_nav_btn("主页", "home"))
        nav.add_widget(make_nav_btn("记录", "records"))
        return nav

    def refresh(self):
        self.list_box.clear_widgets()
        records = load_records(self.records_path)

        if not records:
            self.list_box.add_widget(Label(
                text="暂无记录",
                font_name=APP_FONT_NAME if APP_FONT_NAME else None,
                color=BLACK,
                size_hint_y=None,
                height=dp(48),
            ))
            return

        # 新的放上面
        records_sorted = list(reversed(records))

        for idx_from_end, rec in enumerate(records_sorted):
            card = SoftCard()
            card.set_bg(WHITE)
            card.padding = dp(12)
            card.spacing = dp(6)

            date = rec.get("date", "")
            rec_type = rec.get("type", "normal")

            title = Label(
                text=f"[b]{date}[/b]",
                markup=True,
                font_name=APP_FONT_NAME if APP_FONT_NAME else None,
                color=BLACK,
                font_size=dp(16),
                size_hint_y=None,
                height=dp(26),
                halign="left",
                valign="middle",
            )
            title.bind(size=lambda inst, *_: setattr(inst, "text_size", inst.size))
            card.add_widget(title)

            if rec_type == "cardio_day":
                line = rec.get("text", "今天是有氧日")
                info = Label(
                    text=line,
                    font_name=APP_FONT_NAME if APP_FONT_NAME else None,
                    color=MUTED_TEXT,
                    font_size=dp(15),
                    size_hint_y=None,
                    height=dp(26),
                    halign="left",
                    valign="middle",
                )
                info.bind(size=lambda inst, *_: setattr(inst, "text_size", inst.size))
                card.add_widget(info)
            else:
                part = rec.get("part", "")
                quality = rec.get("quality", "")
                aerobic = rec.get("aerobic", "")
                mins = rec.get("minutes", "")

                text = f"{part} / {quality}"
                if aerobic == "做了":
                    text += f" / 有氧 {mins} 分钟"
                else:
                    text += f" / 无有氧"

                info = Label(
                    text=text,
                    font_name=APP_FONT_NAME if APP_FONT_NAME else None,
                    color=MUTED_TEXT,
                    font_size=dp(15),
                    size_hint_y=None,
                    height=dp(26),
                    halign="left",
                    valign="middle",
                )
                info.bind(size=lambda inst, *_: setattr(inst, "text_size", inst.size))
                card.add_widget(info)

            # 删除按钮（小一点）
            btn_row = BoxLayout(size_hint_y=None, height=dp(42))
            del_btn = Button(
                text="删除",
                font_name=APP_FONT_NAME if APP_FONT_NAME else None,
                font_size=dp(14),
                background_normal="",
                background_color=(0.95, 0.30, 0.30, 1),
                color=WHITE,
                size_hint_x=None,
                width=dp(86),
            )
            # card 内序号要映射到原列表 index
            original_index = len(records) - 1 - idx_from_end

            def _make_del(i):
                def _del(_btn):
                    self._confirm_delete(i)
                return _del
            del_btn.bind(on_press=_make_del(original_index))
            btn_row.add_widget(Widget())
            btn_row.add_widget(del_btn)
            card.add_widget(btn_row)

            self.list_box.add_widget(card)

    def _confirm_delete(self, index):
        box = BoxLayout(orientation="vertical", padding=dp(12), spacing=dp(10))
        box.add_widget(Label(
            text="确定删除这条记录吗？",
            font_name=APP_FONT_NAME if APP_FONT_NAME else None,
            color=BLACK,
        ))

        btns = BoxLayout(size_hint_y=None, height=dp(44), spacing=dp(10))
        cancel = Button(text="取消", background_normal="", background_color=WHITE, color=BLACK)
        ok = Button(text="删除", background_normal="", background_color=(0.95, 0.30, 0.30, 1), color=WHITE)
        btns.add_widget(cancel)
        btns.add_widget(ok)
        box.add_widget(btns)

        pop = Popup(title="", content=box, size_hint=(0.75, 0.3), auto_dismiss=False)
        cancel.bind(on_press=lambda *_: pop.dismiss())

        def do_delete(*_):
            records = load_records(self.records_path)
            if 0 <= index < len(records):
                records.pop(index)
                save_records(self.records_path, records)
            pop.dismiss()
            self.refresh()

        ok.bind(on_press=do_delete)
        pop.open()


class FitnessApp(App):
    def build(self):
        sm = ScreenManager(transition=FadeTransition(duration=0.12))
        sm.add_widget(InputScreen(name="input"))
        sm.add_widget(RecordsScreen(name="records"))
        sm.current = "input"
        return sm


if __name__ == "__main__":
    FitnessApp().run()
