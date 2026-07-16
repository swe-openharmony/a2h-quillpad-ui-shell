import { Style } from '../components/Style';
import { TopBar, IconButton } from '../components/Common';
import { NoteCard } from '../components/NoteCard';
import { NavDrawer } from '../components/NavDrawer';
import { PopupMenu, BottomSheet, MenuRow, DialogCard } from '../components/Overlays';
import { Note, NoteColor } from '../model/Data';
import { AppState, LayoutMode, SortKey, SortDir } from '../state/AppState';
import { promptAction } from '@kit.ArkUI';

@Component
struct MoreVertIcon {
  @Prop color: string = Style.icon;

  build() {
    Column({ space: 3 }) {
      Circle({ width: 4, height: 4 }).fill(this.color)
      Circle({ width: 4, height: 4 }).fill(this.color)
      Circle({ width: 4, height: 4 }).fill(this.color)
    }
    .width(24)
    .height(24)
    .justifyContent(FlexAlign.Center)
  }
}

@Component
export struct MainPage {
  @Prop state: string;
  go: (route: string) => void = () => {};

  @StorageLink('qp_notes_version') notesVersion: number = 0;
  @StorageLink('qp_prefs') prefsSig: string = '';
  @StorageLink('qp_selected') selectedCountMirror: number = 0;
  @StorageLink('qp_show_hidden') showHiddenMirror: boolean = false;
  @StorageLink('qp_toast') toastMirror: string = '';

  @State private sortIndex: number = 5; // default date-modified descending
  @State private overflowShowHiddenChecked: boolean = false;
  @State private moveTarget: string = '';
  @State private contextNoteId: number = 1;

  private sortLabels: string[] = [
    'Title (ascending)',
    'Title (descending)',
    'Date created (ascending)',
    'Date created (descending)',
    'Date modified (ascending)',
    'Date modified (descending)',
  ];

  private app(): AppState { return AppState.getInstance(); }

  private sortRows(): MenuRow[] {
    const rows: MenuRow[] = [];
    for (let i = 0; i < this.sortLabels.length; i++) {
      rows.push({ label: this.sortLabels[i], trailing: 'radio', checked: i === this.sortIndex });
    }
    return rows;
  }

  private overflowRows(): MenuRow[] {
    return [
      { label: 'Layout mode' },
      { label: 'Show hidden notes', trailing: 'checkbox', checked: this.overflowShowHiddenChecked },
      { label: 'Select All' },
    ];
  }

  private selectionMenuRows(): MenuRow[] {
    return [
      { label: 'Pin / Unpin' },
      { label: 'Compact preview' },
      { label: 'Full preview' },
      { label: 'Archive' },
      { label: 'Delete' },
      { label: 'Hide' },
      { label: 'Move to…' },
      { label: 'Duplicate' },
      { label: 'Export' },
      { label: 'Select All' },
    ];
  }

  private contextRows(): MenuRow[] {
    return [
      { label: 'Unpin', icon: $r('app.media.ic_unpin') },
      { label: 'Archive', icon: $r('app.media.ic_archive') },
      { label: 'Move to…', icon: $r('app.media.ic_change_notebook') },
      { label: 'Delete', icon: $r('app.media.ic_bin') },
      { label: 'Hide', icon: $r('app.media.ic_hidden') },
      { label: 'Compact preview', icon: $r('app.media.ic_preview') },
      { label: 'Enable screen always on', icon: $r('app.media.ic_pin') },
      { label: 'Enable markdown', icon: $r('app.media.ic_markdown') },
      { label: 'Duplicate', icon: $r('app.media.ic_duplicate') },
      { label: 'Export', icon: $r('app.media.ic_export_note') },
      { label: 'Share', icon: $r('app.media.ic_share') },
      { label: 'Select more…', icon: $r('app.media.ic_select_more') },
    ];
  }

  private visibleNotes(): Note[] {
    return this.app().visibleMainNotes();
  }

  isSelection(): boolean {
    return this.state === 'main_selection' || this.state === 'main_selection_menu';
  }

  isList(): boolean {
    return this.state === 'main_list_view' || this.app().prefs.layoutMode === LayoutMode.List;
  }

  private notify(msg: string): void {
    try {
      promptAction.showToast({ message: msg, duration: 1800 });
    } catch (e) {
      // ignore
    }
    this.app().showToast(msg);
  }

  private sortedSelectedIds(): number[] {
    return this.app().selectedIds.slice();
  }

  private selectAllVisible(): void {
    const ids: number[] = this.visibleNotes().map((n: Note) => n.id);
    this.app().selectAllVisible(ids);
    this.go('main_selection');
  }

  private handleOverflowPick(label: string): void {
    if (label === 'Layout mode') {
      const next: LayoutMode = this.app().prefs.layoutMode === LayoutMode.Grid ? LayoutMode.List : LayoutMode.Grid;
      this.app().prefs.layoutMode = next;
      this.app().bumpVersion();
      this.go(this.app().prefs.layoutMode === LayoutMode.List ? 'main_list_view' : 'main_grid_default');
      return;
    }
    if (label === 'Show hidden notes') {
      this.app().showHidden = !this.app().showHidden;
      this.overflowShowHiddenChecked = this.app().showHidden;
      this.app().bumpVersion();
      this.go('main_grid_default');
      return;
    }
    if (label === 'Select All') {
      this.selectAllVisible();
      return;
    }
  }

  private handleSelectionPick(label: string): void {
    const app: AppState = this.app();
    if (label === 'Pin / Unpin') {
      const ids: number[] = this.sortedSelectedIds();
      for (let i = 0; i < ids.length; i++) app.togglePinned(ids[i]);
      this.notify('Pinned state updated');
      this.go('main_grid_default');
      return;
    }
    if (label === 'Compact preview' || label === 'Full preview') {
      this.notify('Preview density updated');
      this.go('main_grid_default');
      return;
    }
    if (label === 'Archive') {
      const msg: string = app.archiveSelected();
      this.notify(msg);
      this.go('main_grid_default');
      return;
    }
    if (label === 'Delete') {
      const msg: string = app.deleteSelected();
      this.notify(msg);
      this.go('main_grid_default');
      return;
    }
    if (label === 'Hide') {
      const ids: number[] = this.sortedSelectedIds();
      for (let i = 0; i < ids.length; i++) app.toggleHidden(ids[i]);
      this.notify('Hidden state updated');
      this.go('main_grid_default');
      return;
    }
    if (label === 'Move to…') {
      this.go('main_move_dialog');
      return;
    }
    if (label === 'Duplicate') {
      const msg: string = app.duplicateSelected();
      this.notify(msg);
      this.go('main_grid_default');
      return;
    }
    if (label === 'Export') {
      this.notify('Exported');
      this.go('main_grid_default');
      return;
    }
    if (label === 'Select All') {
      const ids: number[] = this.visibleNotes().map((n: Note) => n.id);
      app.selectAllVisible(ids);
      this.go('main_selection');
      return;
    }
  }

  private handleContextPick(label: string): void {
    const app: AppState = this.app();
    const id: number = this.contextNoteId;
    if (label === 'Unpin' || label === 'Pin') {
      app.togglePinned(id);
      this.go('main_grid_default');
      return;
    }
    if (label === 'Archive') {
      app.selectedIds = [id];
      this.notify(app.archiveSelected());
      this.go('main_grid_default');
      return;
    }
    if (label === 'Delete') {
      app.selectedIds = [id];
      this.notify(app.deleteSelected());
      this.go('main_grid_default');
      return;
    }
    if (label === 'Hide') {
      app.toggleHidden(id);
      this.notify('Hidden state updated');
      this.go('main_grid_default');
      return;
    }
    if (label === 'Compact preview' || label === 'Full preview') {
      this.go('main_grid_default');
      return;
    }
    if (label === 'Enable screen always on') {
      app.updateNote(id, (_n: Note) => {});
      this.go('main_grid_default');
      return;
    }
    if (label === 'Enable markdown') {
      app.toggleMarkdown(id);
      this.go('main_grid_default');
      return;
    }
    if (label === 'Duplicate') {
      app.selectedIds = [id];
      this.notify(app.duplicateSelected());
      this.go('main_grid_default');
      return;
    }
    if (label === 'Export' || label === 'Share') {
      this.notify(label + ' done');
      this.go('main_grid_default');
      return;
    }
    if (label === 'Select more…') {
      // Enter selection mode with this note selected.
      app.selectedIds = [id];
      app.bumpVersion();
      this.go('main_selection');
      return;
    }
  }

  private applySortChoice(index: number): void {
    this.sortIndex = index;
    const keyMap: SortKey[] = [
      SortKey.Title, SortKey.Title, SortKey.Created, SortKey.Created, SortKey.Modified, SortKey.Modified,
    ];
    const dirMap: SortDir[] = [
      SortDir.Asc, SortDir.Desc, SortDir.Asc, SortDir.Desc, SortDir.Asc, SortDir.Desc,
    ];
    this.app().prefs.sortBy = keyMap[index];
    this.app().prefs.sortDir = dirMap[index];
    this.app().bumpVersion();
    this.go('main_grid_default');
  }

  private selectedTitleSuffix(): string {
    const n: number = this.selectedCountMirror;
    return n + (n === 1 ? ' note' : ' notes');
  }

  @Builder overflowButton(onTap: () => void) {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      MoreVertIcon({ color: Style.icon })
    }
    .backgroundColor(Color.Transparent)
    .width(44)
    .height(44)
    .key('toolbar_more')
    .onClick(() => { onTap(); })
  }

  @Builder normalToolbar() {
    TopBar({ leading: $r('app.media.ic_notes'), title: 'Notes',
      onLeading: () => this.go('drawer_nav') }) {
      IconButton({ icon: $r('app.media.ic_search'), keyId: 'toolbar_search', onTap: () => this.go('search_initial') })
      IconButton({ icon: $r('app.media.ic_sort'), keyId: 'toolbar_sort', onTap: () => this.go('main_sort_sheet') })
      this.overflowButton(() => this.go('main_overflow'))
    }
  }

  @Builder selectionToolbar() {
    TopBar({ leading: $r('app.media.ic_back'),
      title: 'Selected ' + this.selectedTitleSuffix(),
      onLeading: () => { this.app().clearSelection(); this.go('main_grid_default'); } }) {
      this.overflowButton(() => this.go('main_selection_menu'))
    }
  }

  @Builder emptyState() {
    Column() {
      Image($r('app.media.ic_notes'))
        .width(96).height(96)
        .fillColor(Style.accent)
        .objectFit(ImageFit.Contain)
      Text('Notes will appear here.')
        .fontSize(16).fontColor(Style.textSecondary)
        .margin({ top: 20 })
    }
    .width('100%').layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder grid() {
    WaterFlow() {
      ForEach(this.visibleNotes(), (n: Note) => {
        FlowItem() {
          NoteCard({
            note: n,
            selected: this.app().isSelected(n.id),
            compactTags: true,
            gridWidth: '100%',
            onTap: () => {
              if (this.isSelection()) {
                this.app().toggleSelected(n.id);
                if (this.app().selectedCount() === 0) this.go('main_grid_default');
              } else {
                this.go('editor_view:' + n.id);
              }
            },
            onLongPress: () => {
              if (this.isSelection()) {
                this.app().toggleSelected(n.id);
              } else {
                this.contextNoteId = n.id;
                this.go('main_context_sheet');
              }
            }
          })
        }
        .width('100%')
        .key('note_card_' + n.id)
      }, (n: Note) => 'g' + n.id + '_' + this.notesVersion)
    }
    .columnsTemplate('1fr 1fr')
    .columnsGap(24).rowsGap(16)
    .width('100%')
    .key('notes_grid')
    .layoutWeight(1)
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .clip(true)
  }

  @Builder linear() {
    List({ space: 12 }) {
      ForEach(this.visibleNotes(), (n: Note) => {
        ListItem() {
          NoteCard({
            note: n,
            compactTags: false,
            gridWidth: '100%',
            listPreviewLimit: 4,
            previewMaxLines: n.id === 2 ? 7 : -1,
            onTap: () => {
              if (this.isSelection()) {
                this.app().toggleSelected(n.id);
                if (this.app().selectedCount() === 0) this.go('main_grid_default');
              } else {
                this.go('editor_view:' + n.id);
              }
            },
            onLongPress: () => {
              if (this.isSelection()) {
                this.app().toggleSelected(n.id);
              } else {
                this.contextNoteId = n.id;
                this.go('main_context_sheet');
              }
            }
          })
        }
        .key('note_card_' + n.id)
      }, (n: Note) => 'l' + n.id + '_' + this.notesVersion)
    }
    .layoutWeight(1).padding(12).key('notes_list')
  }

  @Builder listBody() {
    if (this.visibleNotes().length === 0) {
      this.emptyState()
    } else if (this.isList()) {
      this.linear()
    } else {
      this.grid()
    }
  }

  @Builder bottomBar() {
    Row() {
      IconButton({ icon: $r('app.media.ic_box_checked_outline'), onTap: () => this.go('editor_checklist_create') })
      IconButton({ icon: $r('app.media.ic_file'), onTap: () => this.go('editor_create') })
      IconButton({ icon: $r('app.media.ic_camera'), onTap: () => this.notify('Camera not supported in shell') })
      IconButton({ icon: $r('app.media.ic_microphone'), onTap: () => this.notify('Audio not supported in shell') })
    }
    .width('100%').height(68).padding({ left: 12, right: 12, top: 4, bottom: 8 })
    .justifyContent(FlexAlign.SpaceBetween)
    .backgroundColor('#FFFFFF')
  }

  @Builder moveDialogBody() {
    Column() {
      ForEach(this.moveTargetRows(), (row: MenuRow) => {
        Row() {
          Text(row.label).fontSize(16).fontColor(Style.textPrimary).layoutWeight(1)
          if (row.checked) {
            Image($r('app.media.ic_box_checked')).width(20).height(20).fillColor(Style.accent)
          }
        }
        .width('100%').height(48).alignItems(VerticalAlign.Center)
        .onClick(() => {
          const target: string | null = row.label === 'Unassigned' ? null : row.label;
          this.app().moveSelectedToNotebook(target);
          this.notify('Moved');
          this.go('main_grid_default');
        })
      }, (row: MenuRow) => row.label)
    }
    .width('100%')
  }

  private moveTargetRows(): MenuRow[] {
    const rows: MenuRow[] = [];
    const nbs = this.app().sortedNotebooks();
    for (let i = 0; i < nbs.length; i++) {
      rows.push({ label: nbs[i].name });
    }
    rows.push({ label: 'Unassigned' });
    return rows;
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        if (this.isSelection()) {
          this.selectionToolbar()
        } else {
          this.normalToolbar()
        }
        this.listBody()
        if (!this.isSelection()) {
          this.bottomBar()
        }
      }
      .width('100%').height('100%')

      if (!this.isSelection()) {
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_add')).width(28).height(28).fillColor(Color.White)
        }
        .width(60).height(60).backgroundColor(Style.fabBlue)
        .margin({ right: 18, bottom: 70 })
        .key('fab_create_note')
        .onClick(() => this.go('editor_create'))
      }

      if (this.state === 'main_overflow') {
        PopupMenu({ rows: this.overflowRows(), top: 0, menuWidthPct: 72, rowHeight: 60,
          onPick: (index: number) => this.handleOverflowPick(this.overflowRows()[index].label),
          onDismiss: () => this.go('main_grid_default') })
      }
      if (this.state === 'main_sort_sheet') {
        PopupMenu({ rows: this.sortRows(), top: 0, menuWidthPct: 72, rowHeight: 60,
          onPick: (index: number) => this.applySortChoice(index),
          onDismiss: () => this.go('main_grid_default') })
      }
      if (this.state === 'main_selection_menu') {
        PopupMenu({ rows: this.selectionMenuRows(), top: 0, menuWidthPct: 54, rowHeight: 60,
          onPick: (index: number) => this.handleSelectionPick(this.selectionMenuRows()[index].label),
          onDismiss: () => this.go('main_selection') })
      }
      if (this.state === 'main_context_sheet') {
        BottomSheet({ header: this.contextHeader(), rows: this.contextRows(),
          fullHeight: true, topInset: 24, topRadius: 0, rowHeight: 56,
          onPick: (index: number) => this.handleContextPick(this.contextRows()[index].label),
          onDismiss: () => this.go('main_grid_default') })
      }
      if (this.state === 'main_move_dialog') {
        DialogCard({ title: 'Move to…',
          body: () => { this.moveDialogBody() },
          onDismiss: () => this.go('main_selection') })
      }
      if (this.state === 'drawer_nav') {
        NavDrawer({ onNavigate: (r: string) => this.handleDrawerNavigate(r),
          onDismiss: () => this.go('main_grid_default') })
      }
    }
    .width('100%').height('100%')
  }

  private contextHeader(): string {
    const n: Note | null = this.app().noteById(this.contextNoteId);
    return n === null ? '' : (n as Note).title;
  }

  handleDrawerNavigate(route: string): void {
    if (route === 'main') {
      this.go('main_grid_default');
      return;
    }
    if (route === 'archive') {
      this.go('archive_populated');
      return;
    }
    if (route === 'trash') {
      this.go('trash_populated');
      return;
    }
    if (route === 'notebooks') {
      this.go('notebooks_list');
      return;
    }
    if (route === 'tags') {
      this.go('tags_list');
      return;
    }
    if (route === 'settings') {
      this.go('settings_main_top');
      return;
    }
    if (route === 'about') {
      this.go('about_main');
      return;
    }
    if (route.indexOf('notebook:') === 0) {
      const name: string = route.substring('notebook:'.length);
      this.app().notebookFilter = name;
      this.app().bumpVersion();
      this.go('notebook_notes');
      return;
    }
    this.go(route);
  }
}
