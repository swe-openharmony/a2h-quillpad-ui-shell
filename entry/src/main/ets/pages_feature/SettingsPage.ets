import { Style } from '../components/Style';
import { TopBar } from '../components/Common';
import { DialogCard } from '../components/Overlays';
import { AppState, Prefs } from '../state/AppState';

interface SettingRow {
  header?: string;
  title?: string;
  subtitle?: string;
  icon?: Resource;
  route?: string;
  enabled?: boolean;
  key: string;
}

interface ChoiceItem {
  label: string;
  selected: boolean;
}

@Component
export struct SettingsPage {
  @Prop @Watch('onStateChange') state: string;
  go: (route: string) => void = () => {};
  private scroller: Scroller = new Scroller();

  @StorageLink('qp_prefs') prefsSig: string = '';

  private onStateChange(): void {
    this.applyStateScroll();
  }

  aboutToAppear(): void {
    this.applyStateScroll();
  }

  private app(): AppState { return AppState.getInstance(); }
  private prefs(): Prefs { return this.app().prefs; }

  private rows(): SettingRow[] {
    const p: Prefs = this.prefs();
    return [
      { header: 'General', key: 'h_general' },
      { title: 'Theme mode', subtitle: this.themeLabel(p.themeMode),
        icon: $r('app.media.ic_dark_mode'), route: 'settings_theme_choice', key: 'theme_mode' },
      { title: 'Dark theme mode', subtitle: p.darkThemeMode === 'black' ? 'Black' : 'Standard',
        icon: $r('app.media.ic_dark_mode_variant'), route: 'settings_dark_theme_choice', key: 'dark_theme' },
      { title: 'Color scheme', subtitle: p.colorScheme, icon: $r('app.media.ic_color'),
        route: 'settings_color_scheme', key: 'color_scheme' },
      { header: 'View', key: 'h_view' },
      { header: 'Notebook', key: 'h_notebook' },
      { title: 'Layout mode', subtitle: p.layoutMode === 'list' ? 'List' : 'Grid',
        icon: $r('app.media.ic_grid'), route: 'settings_layout_choice', key: 'layout_mode' },
      { title: 'Sort by',
        subtitle: this.sortLabel(p.sortBy, p.sortDir),
        icon: $r('app.media.ic_sort'), route: 'settings_sort_choice', key: 'sort_by' },
      { header: 'Note content', key: 'h_note_content' },
      { title: 'Text editor/view font size', subtitle: p.fontSize, icon: $r('app.media.ic_header'),
        route: 'settings_font_size_choice', key: 'font_size' },
      { title: 'Edit/View note button position',
        subtitle: p.buttonPosition === 'topbar' ? 'Top bar' : 'Floating button',
        icon: $r('app.media.ic_pencil'), route: 'settings_button_position_choice', key: 'button_position' },
      { title: 'Default editor mode',
        subtitle: p.defaultEditorMode === 'edit' ? 'Edit mode' : 'View mode',
        icon: $r('app.media.ic_preview'), route: 'settings_default_editor_choice', key: 'editor_mode' },
      { title: 'Show date created/modified', subtitle: p.showDate, icon: $r('app.media.ic_date'),
        route: 'settings_show_date_choice', key: 'show_date' },
      { title: 'Date format', subtitle: p.dateFormat, icon: $r('app.media.ic_date'),
        route: 'settings_date_format_choice', key: 'date_format' },
      { title: 'Time format', subtitle: p.timeFormat === '24-hour' ? '24-hour' : '12-hour',
        icon: $r('app.media.ic_time'), route: 'settings_time_format_choice', key: 'time_format' },
      { header: 'Tag list', key: 'h_tag_list' },
      { title: 'Tag list sort',
        subtitle: this.sortLabel(p.tagSortBy, p.tagSortDir),
        icon: $r('app.media.ic_sort'), route: 'settings_tag_sort_choice', key: 'tag_sort' },
      { title: 'Notebook list sort',
        subtitle: this.sortLabel(p.notebookSortBy, p.notebookSortDir),
        icon: $r('app.media.ic_sort'), route: 'settings_notebook_sort_choice', key: 'notebook_sort' },
      { title: 'Group notes without a notebook', subtitle: p.groupNoNotebook,
        icon: $r('app.media.ic_notes'), route: 'settings_group_no_notebook_choice', key: 'group_no_notebook' },
      { title: 'Move (un)checked items in the lists', subtitle: p.moveChecked,
        icon: $r('app.media.ic_box_checked'), route: 'settings_move_checked_choice', key: 'move_checked' },
      { title: 'Open media in', subtitle: p.openMedia,
        icon: $r('app.media.ic_file'), route: 'settings_open_media_choice', key: 'open_media' },
      { title: 'Delete notes in bin', subtitle: p.deletionTime, icon: $r('app.media.ic_bin'),
        route: 'settings_deletion_time_choice', key: 'delete_bin' },
      { header: 'Backup', key: 'h_backup' },
      { title: 'Create a backup', subtitle: 'Export all notes to a backup file.',
        icon: $r('app.media.ic_backup_settings'), key: 'create_backup' },
      { title: 'Restore', subtitle: 'Load notes from a backup file.',
        icon: $r('app.media.ic_restore'), key: 'restore' },
      { title: 'Backup strategy for attachments', subtitle: p.backupStrategy,
        icon: $r('app.media.ic_file'), route: 'settings_backup_strategy_choice', key: 'backup_strategy' },
      { header: 'Syncing', key: 'h_syncing' },
      { title: 'Go to sync settings', subtitle: 'Currently not syncing',
        icon: $r('app.media.ic_sync_settings'), route: 'sync_main', key: 'sync_settings' }
    ];
  }

  private themeLabel(t: string): string {
    if (t === 'dark') return 'Dark';
    if (t === 'light') return 'Light';
    return 'Follow system';
  }

  private sortLabel(k: string, d: string): string {
    const base: string = k === 'title' ? 'Title' : k === 'created' ? 'Date created' : 'Date modified';
    return base + ' (' + (d === 'asc' ? 'ascending' : 'descending') + ')';
  }

  visibleRows(): SettingRow[] {
    // All settings rows are always visible in the Scroll; the user scrolls
    // to reach rows further down. Choice dialog overlays (theme, color, etc.)
    // do not affect which rows are mounted — they sit on top of the full list.
    return this.rows();
  }

  private applyStateScroll(): void {
    // top/mid/bottom slices are the source-faithful paging model.
  }

  private themeChoices(): ChoiceItem[] {
    const p = this.prefs();
    return [
      { label: 'Follow system', selected: p.themeMode === 'system' },
      { label: 'Dark', selected: p.themeMode === 'dark' },
      { label: 'Light', selected: p.themeMode === 'light' },
    ];
  }
  private darkChoices(): ChoiceItem[] {
    const p = this.prefs();
    return [
      { label: 'Standard', selected: p.darkThemeMode === 'standard' },
      { label: 'Black', selected: p.darkThemeMode === 'black' },
    ];
  }
  private colorChoices(): ChoiceItem[] {
    const p = this.prefs();
    const colors: string[] = ['Blue', 'Red', 'Yellow', 'Green', 'Pink', 'Orange', 'Purple'];
    const out: ChoiceItem[] = [];
    for (let i = 0; i < colors.length; i++) {
      out.push({ label: colors[i], selected: p.colorScheme === colors[i] });
    }
    return out;
  }
  private layoutChoices(): ChoiceItem[] {
    const p = this.prefs();
    return [
      { label: 'Grid', selected: p.layoutMode === 'grid' },
      { label: 'List', selected: p.layoutMode === 'list' },
    ];
  }
  private sortChoices(): ChoiceItem[] {
    const p = this.prefs();
    const labels: string[] = [
      'Title (ascending)', 'Title (descending)',
      'Date created (ascending)', 'Date created (descending)',
      'Date modified (ascending)', 'Date modified (descending)',
    ];
    const cur: string = this.sortLabel(p.sortBy, p.sortDir);
    const out: ChoiceItem[] = [];
    for (let i = 0; i < labels.length; i++) {
      out.push({ label: labels[i], selected: labels[i] === cur });
    }
    return out;
  }
  private tagSortChoices(): ChoiceItem[] {
    const p = this.prefs();
    const labels: string[] = [
      'Title (ascending)', 'Title (descending)',
      'Date created (ascending)', 'Date created (descending)',
    ];
    const cur: string = this.sortLabel(p.tagSortBy, p.tagSortDir);
    const out: ChoiceItem[] = [];
    for (let i = 0; i < labels.length; i++) {
      out.push({ label: labels[i], selected: labels[i] === cur });
    }
    return out;
  }
  private notebookSortChoices(): ChoiceItem[] {
    const p = this.prefs();
    const labels: string[] = [
      'Title (ascending)', 'Title (descending)',
      'Date created (ascending)', 'Date created (descending)',
    ];
    const cur: string = this.sortLabel(p.notebookSortBy, p.notebookSortDir);
    const out: ChoiceItem[] = [];
    for (let i = 0; i < labels.length; i++) {
      out.push({ label: labels[i], selected: labels[i] === cur });
    }
    return out;
  }
  private fontSizeChoices(): ChoiceItem[] {
    const p = this.prefs();
    const sizes: string[] = ['Default', 'Small', 'Medium', 'Large', 'Huge'];
    const out: ChoiceItem[] = [];
    for (let i = 0; i < sizes.length; i++) {
      out.push({ label: sizes[i], selected: p.fontSize === sizes[i] });
    }
    return out;
  }
  private buttonPositionChoices(): ChoiceItem[] {
    const p = this.prefs();
    return [
      { label: 'Floating button', selected: p.buttonPosition === 'floating' },
      { label: 'Top bar', selected: p.buttonPosition === 'topbar' },
    ];
  }
  private editorModeChoices(): ChoiceItem[] {
    const p = this.prefs();
    return [
      { label: 'View mode', selected: p.defaultEditorMode === 'view' },
      { label: 'Edit mode', selected: p.defaultEditorMode === 'edit' },
    ];
  }
  private yesNoChoices(current: string): ChoiceItem[] {
    return [
      { label: 'Yes', selected: current === 'Yes' },
      { label: 'No', selected: current === 'No' },
    ];
  }
  private dateFormatChoices(): ChoiceItem[] {
    const p = this.prefs();
    const list: string[] = ['June 29 2026', '29 June 2026', '2026/06/29', '06/29/2026'];
    const out: ChoiceItem[] = [];
    for (let i = 0; i < list.length; i++) {
      out.push({ label: list[i], selected: p.dateFormat === list[i] });
    }
    return out;
  }
  private timeFormatChoices(): ChoiceItem[] {
    const p = this.prefs();
    return [
      { label: '12-hour', selected: p.timeFormat === '12-hour' },
      { label: '24-hour', selected: p.timeFormat === '24-hour' },
    ];
  }
  private openMediaChoices(): ChoiceItem[] {
    const p = this.prefs();
    return [
      { label: 'Internal', selected: p.openMedia === 'Internal' },
      { label: 'External', selected: p.openMedia === 'External' },
    ];
  }
  private deletionTimeChoices(): ChoiceItem[] {
    const p = this.prefs();
    const list: string[] = ['Never', 'Instantly', 'After 7 days', 'After 2 weeks', 'After 1 month'];
    const out: ChoiceItem[] = [];
    for (let i = 0; i < list.length; i++) {
      out.push({ label: list[i], selected: p.deletionTime === list[i] });
    }
    return out;
  }
  private backupStrategyChoices(): ChoiceItem[] {
    const p = this.prefs();
    return [
      { label: 'Backup everything', selected: p.backupStrategy === 'Backup everything' },
      { label: 'Skip attachments', selected: p.backupStrategy === 'Skip attachments' },
    ];
  }

  @Builder sectionHeader(text: string) {
    Text(text)
      .fontSize(15)
      .fontColor(Style.accent)
      .fontWeight(FontWeight.Bold)
      .width('100%')
      .padding({ left: 16, top: 22, bottom: 10 })
  }

  @Builder settingRow(row: SettingRow) {
    Row() {
      if (row.icon) {
        Image(row.icon)
          .width(24).height(24)
          .fillColor(Style.icon)
          .objectFit(ImageFit.Contain)
          .margin({ right: 28 })
      }
      Column() {
        Text(row.title)
          .fontSize(16).fontColor(Style.textPrimary)
          .width('100%')
        if (row.subtitle && row.subtitle.length > 0) {
          Text(row.subtitle)
            .fontSize(14).fontColor(Style.textSecondary)
            .width('100%').margin({ top: 3 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .constraintSize({ minHeight: 68 })
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
    .key('settings_row_' + row.key)
    .enabled(row.enabled !== false)
    .onClick(() => {
      if (row.route && row.route.length > 0) {
        this.go(row.route);
      }
    })
  }

  @Builder radioIndicator(selected: boolean) {
    Stack() {
      Row()
        .width(20)
        .height(20)
        .border({ width: 2, color: selected ? Style.accent : '#757983', radius: 10 })
        .backgroundColor('#FFFFFF')
      if (selected) {
        Circle({ width: 10, height: 10 }).fill(Style.accent)
      }
    }
    .width(28)
    .height(28)
    .margin({ right: 20 })
  }

  @Builder choiceBody(items: ChoiceItem[], onPick: (label: string) => void) {
    Column() {
      ForEach(items, (c: ChoiceItem) => {
        Row() {
          this.radioIndicator(c.selected)
          Text(c.label).fontSize(18).fontColor(Style.textSecondary).layoutWeight(1)
        }
        .key('settings_choice_' + c.label)
        .width('100%').height(56).alignItems(VerticalAlign.Center)
        .onClick(() => onPick(c.label))
      }, (c: ChoiceItem) => c.label)
    }
    .width('100%')
  }

  @Builder doneAction() {
    Text('DONE!')
      .fontSize(16).fontColor(Style.accent).fontWeight(FontWeight.Medium)
      .padding({ left: 12, right: 8, top: 6, bottom: 6 })
      .onClick(() => this.go('settings_main_top'))
  }

  build() {
    Stack() {
      Column() {
        TopBar({ leading: $r('app.media.ic_back'), title: 'Settings',
          onLeading: () => this.go('main_grid_default') })
        Scroll(this.scroller) {
          Column() {
            ForEach(this.visibleRows(), (row: SettingRow) => {
              if (row.header && row.header.length > 0) {
                this.sectionHeader(row.header)
              } else {
                this.settingRow(row)
              }
            }, (row: SettingRow) => row.key + '_' + this.prefsSig)
          }
          .width('100%')
          .padding({ bottom: 40 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.TopStart)
      }
      .width('100%').height('100%')

      if (this.state === 'settings_theme_choice') {
        DialogCard({ title: 'Theme mode', onDismiss: () => this.go('settings_main_top'),
          body: () => { this.choiceBody(this.themeChoices(), (l: string) => {
            this.app().setPref('themeMode', l);
          }) },
          actions: () => { this.doneAction() } })
      }
      if (this.state === 'settings_dark_theme_choice') {
        DialogCard({ title: 'Dark theme mode', onDismiss: () => this.go('settings_main_top'),
          body: () => { this.choiceBody(this.darkChoices(), (l: string) => {
            this.app().setPref('darkThemeMode', l === 'Black' ? 'black' : 'standard');
          }) },
          actions: () => { this.doneAction() } })
      }
      if (this.state === 'settings_color_scheme') {
        DialogCard({ title: 'Color scheme', onDismiss: () => this.go('settings_main_top'),
          body: () => { this.choiceBody(this.colorChoices(), (l: string) => {
            this.app().setPref('colorScheme', l);
          }) },
          actions: () => { this.doneAction() } })
      }
      if (this.state === 'settings_layout_choice') {
        DialogCard({ title: 'Layout mode', onDismiss: () => this.go('settings_main_top'),
          body: () => { this.choiceBody(this.layoutChoices(), (l: string) => {
            this.app().setPref('layoutMode', l === 'List' ? 'list' : 'grid');
          }) },
          actions: () => { this.doneAction() } })
      }
      if (this.state === 'settings_sort_choice') {
        DialogCard({ title: 'Sort by', onDismiss: () => this.go('settings_main_top'),
          body: () => { this.choiceBody(this.sortChoices(), (l: string) => {
            this.applySortChoice(l, 'sortBy', 'sortDir');
          }) },
          actions: () => { this.doneAction() } })
      }
      if (this.state === 'settings_tag_sort_choice') {
        DialogCard({ title: 'Tag list sort', onDismiss: () => this.go('settings_main_top'),
          body: () => { this.choiceBody(this.tagSortChoices(), (l: string) => {
            this.applySortChoice(l, 'tagSortBy', 'tagSortDir');
          }) },
          actions: () => { this.doneAction() } })
      }
      if (this.state === 'settings_notebook_sort_choice') {
        DialogCard({ title: 'Notebook list sort', onDismiss: () => this.go('settings_main_top'),
          body: () => { this.choiceBody(this.notebookSortChoices(), (l: string) => {
            this.applySortChoice(l, 'notebookSortBy', 'notebookSortDir');
          }) },
          actions: () => { this.doneAction() } })
      }
      if (this.state === 'settings_font_size_choice') {
        DialogCard({ title: 'Text editor/view font size', onDismiss: () => this.go('settings_main_top'),
          body: () => { this.choiceBody(this.fontSizeChoices(), (l: string) => {
            this.app().setPref('fontSize', l);
          }) },
          actions: () => { this.doneAction() } })
      }
      if (this.state === 'settings_button_position_choice') {
        DialogCard({ title: 'Edit/View note button position', onDismiss: () => this.go('settings_main_top'),
          body: () => { this.choiceBody(this.buttonPositionChoices(), (l: string) => {
            this.app().setPref('buttonPosition', l === 'Top bar' ? 'topbar' : 'floating');
          }) },
          actions: () => { this.doneAction() } })
      }
      if (this.state === 'settings_default_editor_choice') {
        DialogCard({ title: 'Default editor mode', onDismiss: () => this.go('settings_main_top'),
          body: () => { this.choiceBody(this.editorModeChoices(), (l: string) => {
            this.app().setPref('defaultEditorMode', l === 'Edit mode' ? 'edit' : 'view');
          }) },
          actions: () => { this.doneAction() } })
      }
      if (this.state === 'settings_show_date_choice') {
        DialogCard({ title: 'Show date created/modified', onDismiss: () => this.go('settings_main_top'),
          body: () => { this.choiceBody(this.yesNoChoices(this.prefs().showDate), (l: string) => {
            this.app().setPref('showDate', l);
          }) },
          actions: () => { this.doneAction() } })
      }
      if (this.state === 'settings_date_format_choice') {
        DialogCard({ title: 'Date format', onDismiss: () => this.go('settings_main_top'),
          body: () => { this.choiceBody(this.dateFormatChoices(), (l: string) => {
            this.app().setPref('dateFormat', l);
          }) },
          actions: () => { this.doneAction() } })
      }
      if (this.state === 'settings_time_format_choice') {
        DialogCard({ title: 'Time format', onDismiss: () => this.go('settings_main_top'),
          body: () => { this.choiceBody(this.timeFormatChoices(), (l: string) => {
            this.app().setPref('timeFormat', l);
          }) },
          actions: () => { this.doneAction() } })
      }
      if (this.state === 'settings_group_no_notebook_choice') {
        DialogCard({ title: 'Group notes without a notebook', onDismiss: () => this.go('settings_main_top'),
          body: () => { this.choiceBody(this.yesNoChoices(this.prefs().groupNoNotebook), (l: string) => {
            this.app().setPref('groupNoNotebook', l);
          }) },
          actions: () => { this.doneAction() } })
      }
      if (this.state === 'settings_move_checked_choice') {
        DialogCard({ title: 'Move (un)checked items in the lists', onDismiss: () => this.go('settings_main_top'),
          body: () => { this.choiceBody(this.yesNoChoices(this.prefs().moveChecked), (l: string) => {
            this.app().setPref('moveChecked', l);
          }) },
          actions: () => { this.doneAction() } })
      }
      if (this.state === 'settings_open_media_choice') {
        DialogCard({ title: 'Open media in', onDismiss: () => this.go('settings_main_top'),
          body: () => { this.choiceBody(this.openMediaChoices(), (l: string) => {
            this.app().setPref('openMedia', l);
          }) },
          actions: () => { this.doneAction() } })
      }
      if (this.state === 'settings_deletion_time_choice') {
        DialogCard({ title: 'Delete notes in bin', onDismiss: () => this.go('settings_main_top'),
          body: () => { this.choiceBody(this.deletionTimeChoices(), (l: string) => {
            this.app().setPref('deletionTime', l);
          }) },
          actions: () => { this.doneAction() } })
      }
      if (this.state === 'settings_backup_strategy_choice') {
        DialogCard({ title: 'Backup strategy for attachments', onDismiss: () => this.go('settings_main_top'),
          body: () => { this.choiceBody(this.backupStrategyChoices(), (l: string) => {
            this.app().setPref('backupStrategy', l);
          }) },
          actions: () => { this.doneAction() } })
      }
    }
    .width('100%').height('100%')
    .backgroundColor(Style.bg)
  }

  private applySortChoice(label: string, sortKeyPref: string, sortDirPref: string): void {
    // Map label back to (key, dir) and persist.
    if (label.indexOf('Title') === 0) {
      this.app().setPref(sortKeyPref, 'title');
    } else if (label.indexOf('Date created') === 0) {
      this.app().setPref(sortKeyPref, 'created');
    } else {
      this.app().setPref(sortKeyPref, 'modified');
    }
    this.app().setPref(sortDirPref, label.indexOf('ascending') > 0 ? 'asc' : 'desc');
  }
}
