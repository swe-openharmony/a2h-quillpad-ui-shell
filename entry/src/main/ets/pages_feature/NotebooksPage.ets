import { Style } from '../components/Style';
import { TopBar, IconButton } from '../components/Common';
import { NoteCard } from '../components/NoteCard';
import { BottomSheet, PopupMenu, MenuRow, InputDialogCard, DialogCard } from '../components/Overlays';
import { Notebook, Note } from '../model/Data';
import { AppState, SortKey, SortDir } from '../state/AppState';
import { promptAction } from '@kit.ArkUI';

@Component
export struct NotebooksPage {
  @Prop state: string;
  go: (route: string) => void = () => {};

  @StorageLink('qp_notes_version') notesVersion: number = 0;
  @State private notebookNameDraft: string = '';
  @State private renameDraft: string = '';
  @State private renameTargetId: number = -1;
  @State private contextNotebookId: number = 1;
  @State private sortIndex: number = 0;

  private app(): AppState { return AppState.getInstance(); }

  private notebooks(): Notebook[] {
    return this.app().sortedNotebooks();
  }

  private sortLabels: string[] = [
    'Title (ascending)',
    'Title (descending)',
    'Date created (ascending)',
    'Date created (descending)',
  ];

  private sortRows(): MenuRow[] {
    const rows: MenuRow[] = [];
    for (let i = 0; i < this.sortLabels.length; i++) {
      rows.push({ label: this.sortLabels[i], trailing: 'radio', checked: i === this.sortIndex });
    }
    return rows;
  }

  private contextRows(): MenuRow[] {
    return [
      { label: 'Rename notebook', icon: $r('app.media.ic_pencil') },
      { label: 'Delete', icon: $r('app.media.ic_bin') },
      { label: 'Select more…', icon: $r('app.media.ic_select_more') },
    ];
  }

  private filteredNotes(name: string): Note[] {
    return this.app().visibleNotebookNotes(name);
  }

  private currentFilter(): string {
    return this.app().notebookFilter;
  }

  private currentFilterTitle(): string {
    return this.currentFilter() === '__none__' ? 'No Notebook' : this.currentFilter();
  }

  private notify(msg: string): void {
    try { promptAction.showToast({ message: msg, duration: 1500 }); } catch (e) {}
  }

  @Builder listToolbar() {
    TopBar({ leading: $r('app.media.ic_back'), title: 'Notebooks',
      onLeading: () => this.go('main_grid_default') }) {
      IconButton({ icon: $r('app.media.ic_sort'), keyId: 'notebooks_sort', onTap: () => this.go('notebooks_sort') })
      IconButton({ icon: $r('app.media.ic_add'), keyId: 'toolbar_notebook_add', onTap: () => {
        this.notebookNameDraft = '';
        this.go('notebook_create');
      } })
    }
  }

  @Builder notebookRow(nb: Notebook) {
    Row() {
      Image($r('app.media.ic_notebook'))
        .width(Style.iconSize).height(Style.iconSize)
        .fillColor(Style.icon).margin({ right: 28 })
      Text(nb.name).fontSize(18).fontColor(Style.textPrimary).layoutWeight(1)
    }
    .width('100%').height(56).padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .key('notebook_row_' + nb.id)
  }

  @Builder notebooksList() {
    Column() {
      this.listToolbar()
      if (this.notebooks().length === 0) {
        Column() {
          Text('No notebooks yet.')
            .fontSize(16).fontColor(Style.textSecondary)
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.notebooks(), (nb: Notebook) => {
            ListItem() {
              this.notebookRow(nb)
            }
            .onClick(() => {
              this.app().notebookFilter = nb.name;
              this.app().bumpVersion();
              this.go('notebook_notes');
            })
            .gesture(LongPressGesture().onAction(() => {
              this.contextNotebookId = nb.id;
              this.go('notebook_context');
            }))
          }, (nb: Notebook) => 'nb' + nb.id + nb.name + this.notesVersion)
        }
        .layoutWeight(1)
      }
    }
    .width('100%').height('100%')
  }

  @Builder createDialogBody() {
    TextInput({ text: this.notebookNameDraft, placeholder: 'Notebook name' })
      .placeholderColor(Style.textHint)
      .fontColor(Style.textPrimary)
      .backgroundColor(Color.Transparent)
      .borderRadius(0)
      .padding({ left: 0, right: 0 })
      .border({ width: { bottom: 1 }, color: Style.divider })
      .width('100%')
      .defaultFocus(true)
      .enableKeyboardOnFocus(true)
      .key('notebook_name_input')
      .onChange((value: string) => { this.notebookNameDraft = value })
  }

  @Builder createDialogActions() {
    Text('SAVE')
      .fontSize(16).fontColor(Style.accent).fontWeight(FontWeight.Medium)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .key('notebook_save')
      .onClick(() => {
        const err: string = this.app().createNotebook(this.notebookNameDraft);
        if (err.length > 0) {
          this.notify(err);
          return; // keep dialog open
        }
        this.go('notebooks_list');
      })
  }

  @Builder renameDialogBody() {
    TextInput({ text: this.renameDraft, placeholder: 'Notebook name' })
      .placeholderColor(Style.textHint)
      .fontColor(Style.textPrimary)
      .backgroundColor(Color.Transparent)
      .borderRadius(0)
      .padding({ left: 0, right: 0 })
      .border({ width: { bottom: 1 }, color: Style.divider })
      .width('100%')
      .defaultFocus(true)
      .enableKeyboardOnFocus(true)
      .key('notebook_name_input')
      .onChange((value: string) => { this.renameDraft = value })
  }

  @Builder renameDialogActions() {
    Text('SAVE')
      .fontSize(16).fontColor(Style.accent).fontWeight(FontWeight.Medium)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .key('notebook_rename_save')
      .onClick(() => {
        const err: string = this.app().renameNotebook(this.renameTargetId, this.renameDraft);
        if (err.length > 0) {
          this.notify(err);
          return;
        }
        this.go('notebooks_list');
      })
  }

  @Builder notebookBottomBar() {
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

  @Builder notebookGrid() {
    WaterFlow() {
      ForEach(this.filteredNotes(this.currentFilter()), (n: Note) => {
        FlowItem() {
          NoteCard({
            note: n,
            compactTags: false,
            gridWidth: '100%',
            onTap: () => this.go('editor_view:' + n.id)
          })
        }
        .width('100%')
        .key('nb_note_card_' + n.id)
      }, (n: Note) => 'wn' + n.id + '_' + this.notesVersion)
    }
    .columnsTemplate('1fr 1fr')
    .columnsGap(24).rowsGap(16)
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .clip(true)
  }

  @Builder notebookNotes() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        TopBar({ leading: $r('app.media.ic_notes'), title: this.currentFilterTitle(),
          onLeading: () => this.go('drawer_nav') }) {
          IconButton({ icon: $r('app.media.ic_search'), onTap: () => this.go('search_initial') })
          IconButton({ icon: $r('app.media.ic_sort'), onTap: () => this.go('notebook_notes_sort') })
          IconButton({ icon: $r('app.media.ic_select_more'), onTap: () => this.notify('Selection mode') })
        }
        this.notebookGrid()
        this.notebookBottomBar()
      }
      .width('100%').height('100%')

      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_add')).width(28).height(28).fillColor(Color.White)
      }
      .width(60).height(60).backgroundColor(Style.fabBlue)
      .margin({ right: 18, bottom: 70 })
      .onClick(() => this.go('editor_create'))
    }
    .width('100%').height('100%')
  }

  private applySort(index: number): void {
    this.sortIndex = index;
    const keys: SortKey[] = [SortKey.Title, SortKey.Title, SortKey.Created, SortKey.Created];
    const dirs: SortDir[] = [SortDir.Asc, SortDir.Desc, SortDir.Asc, SortDir.Desc];
    this.app().prefs.notebookSortBy = keys[index];
    this.app().prefs.notebookSortDir = dirs[index];
    this.app().bumpVersion();
    this.go('notebooks_list');
  }

  build() {
    Stack() {
      if (this.state === 'notebook_notes') {
        this.notebookNotes()
      } else {
        this.notebooksList()
      }

      if (this.state === 'notebook_create') {
        InputDialogCard({ title: 'New notebook', top: 320,
          body: () => { this.createDialogBody() },
          actions: () => { this.createDialogActions() },
          onDismiss: () => this.go('notebooks_list') })
      }
      if (this.state === 'notebook_rename') {
        InputDialogCard({ title: 'Rename notebook', top: 320,
          body: () => { this.renameDialogBody() },
          actions: () => { this.renameDialogActions() },
          onDismiss: () => this.go('notebooks_list') })
      }
      if (this.state === 'notebook_context') {
        BottomSheet({ header: this.contextHeader(), rows: this.contextRows(),
          topRadius: 0, rowHeight: 64,
          onPick: (index: number) => this.handleContext(this.contextRows()[index].label),
          onDismiss: () => this.go('notebooks_list') })
      }
      if (this.state === 'notebooks_sort' || this.state === 'notebook_notes_sort') {
        PopupMenu({ rows: this.sortRows(), top: 16, menuWidthPct: 60, rowHeight: 56,
          onPick: (index: number) => this.applySort(index),
          onDismiss: () => this.go(this.state === 'notebook_notes_sort' ? 'notebook_notes' : 'notebooks_list') })
      }
    }
    .width('100%').height('100%')
  }

  private contextHeader(): string {
    const nbs: Notebook[] = this.notebooks();
    for (let i = 0; i < nbs.length; i++) {
      if (nbs[i].id === this.contextNotebookId) return nbs[i].name;
    }
    return '';
  }

  private handleContext(label: string): void {
    const id: number = this.contextNotebookId;
    if (label === 'Rename notebook') {
      this.renameTargetId = id;
      this.renameDraft = this.contextHeader();
      this.go('notebook_rename');
      return;
    }
    if (label === 'Delete') {
      this.app().deleteNotebook(id);
      this.notify('Notebook deleted');
      this.go('notebooks_list');
      return;
    }
    if (label === 'Select more…') {
      this.notify('Multi-select not supported');
      this.go('notebooks_list');
      return;
    }
  }
}
