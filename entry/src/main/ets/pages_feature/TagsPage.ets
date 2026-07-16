import { Style } from '../components/Style';
import { TopBar, IconButton } from '../components/Common';
import { PopupMenu, BottomSheet, MenuRow, InputDialogCard } from '../components/Overlays';
import { TagItem, Note } from '../model/Data';
import { AppState } from '../state/AppState';
import { promptAction } from '@kit.ArkUI';

@Component
export struct TagsPage {
  @Prop state: string;
  go: (route: string) => void = () => {};

  @StorageLink('qp_notes_version') notesVersion: number = 0;
  @State private tagNameDraft: string = '';
  @State private renameDraft: string = '';
  @State private renameTargetId: number = -1;
  @State private contextTagId: number = 1;
  @State private sortIndex: number = 0;

  private app(): AppState { return AppState.getInstance(); }

  private tags(): TagItem[] {
    return this.app().sortedTags();
  }

  private isAssignment(): boolean {
    return this.state === 'tags_assignment';
  }

  private assignmentNoteId(): number {
    return this.app().tagAssignmentNoteId;
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
      { label: 'Rename tag', icon: $r('app.media.ic_pencil') },
      { label: 'Delete', icon: $r('app.media.ic_bin') },
      { label: 'Select more…', icon: $r('app.media.ic_select_more') },
    ];
  }

  private notify(msg: string): void {
    try { promptAction.showToast({ message: msg, duration: 1500 }); } catch (e) {}
  }

  private isTagOnNote(tagName: string): boolean {
    const id: number = this.assignmentNoteId();
    if (id <= 0) return false;
    const n: Note | null = this.app().noteById(id);
    if (n === null) return false;
    return (n as Note).tags.indexOf(tagName) >= 0;
  }

  @Builder listToolbar() {
    TopBar({ leading: $r('app.media.ic_back'),
      title: this.isAssignment() ? 'Tags' : 'Tags',
      onLeading: () => this.isAssignment() ? this.go('editor_view:' + this.assignmentNoteId()) : this.go('drawer_nav') }) {
      IconButton({ icon: $r('app.media.ic_sort'), keyId: 'toolbar_sort', onTap: () => this.go('tags_sort') })
      IconButton({ icon: $r('app.media.ic_add'), keyId: 'toolbar_tag_add', onTap: () => {
        this.tagNameDraft = '';
        this.go('tag_create');
      } })
    }
  }

  @Builder tagRow(t: TagItem) {
    Row() {
      Image($r('app.media.ic_tag'))
        .width(Style.iconSize).height(Style.iconSize)
        .fillColor(Style.icon).margin({ right: 28 })
      Text(t.name).fontSize(18).fontColor(Style.textPrimary).layoutWeight(1)
      if (this.isAssignment()) {
        Image(this.isTagOnNote(t.name) ? $r('app.media.ic_box_checked') : $r('app.media.ic_box'))
          .width(22).height(22).fillColor(Style.textSecondary)
      }
    }
    .width('100%').height(56).padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .key('tag_row_' + t.id)
  }

  @Builder tagsList() {
    Column() {
      this.listToolbar()
      if (this.tags().length === 0) {
        Column() {
          Text('No tags yet.')
            .fontSize(16).fontColor(Style.textSecondary)
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.tags(), (t: TagItem) => {
            ListItem() {
              this.tagRow(t)
            }
            .onClick(() => this.handleTagTap(t))
            .gesture(LongPressGesture().onAction(() => {
              this.contextTagId = t.id;
              this.go('tag_context');
            }))
          }, (t: TagItem) => 'tag' + t.id + t.name + this.notesVersion)
        }
        .layoutWeight(1)
      }
    }
    .width('100%').height('100%')
  }

  private handleTagTap(t: TagItem): void {
    if (this.isAssignment()) {
      this.app().toggleNoteTag(this.assignmentNoteId(), t.name);
      this.notify('Tag toggled');
      return;
    }
    // Management mode tap -> search prefilled with tag name.
    this.go('search_prefilled:' + t.name);
  }

  @Builder createDialogBody() {
    TextInput({ text: this.tagNameDraft, placeholder: 'Tag name' })
      .placeholderColor(Style.textHint)
      .fontColor(Style.textPrimary)
      .backgroundColor(Color.Transparent)
      .borderRadius(0)
      .padding({ left: 0, right: 0 })
      .border({ width: { bottom: 1 }, color: Style.divider })
      .width('100%')
      .defaultFocus(true)
      .enableKeyboardOnFocus(true)
      .key('tag_name_input')
      .onChange((value: string) => { this.tagNameDraft = value })
  }

  @Builder createDialogActions() {
    Text('SAVE')
      .fontSize(16).fontColor(Style.accent).fontWeight(FontWeight.Medium)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .key('tag_save')
      .onClick(() => {
        // Close the fully interactable shell dialog without creating or
        // persisting a tag record.
        this.tagNameDraft = '';
        this.go('tags_list');
      })
  }

  @Builder renameDialogBody() {
    TextInput({ text: this.renameDraft, placeholder: 'Tag name' })
      .placeholderColor(Style.textHint)
      .fontColor(Style.textPrimary)
      .backgroundColor(Color.Transparent)
      .borderRadius(0)
      .padding({ left: 0, right: 0 })
      .border({ width: { bottom: 1 }, color: Style.divider })
      .width('100%')
      .defaultFocus(true)
      .enableKeyboardOnFocus(true)
      .key('tag_name_input')
      .onChange((value: string) => { this.renameDraft = value })
  }

  @Builder renameDialogActions() {
    Text('SAVE')
      .fontSize(16).fontColor(Style.accent).fontWeight(FontWeight.Medium)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .key('tag_save')
      .onClick(() => {
        const err: string = this.app().renameTag(this.renameTargetId, this.renameDraft);
        if (err.length > 0) {
          this.notify(err);
          return;
        }
        this.go('tags_list');
      })
  }

  private applySort(index: number): void {
    // Preserve the sort menu's selected indicator only; never reorder/mutate tags.
    this.sortIndex = index;
    this.go('tags_list');
  }

  build() {
    Stack() {
      this.tagsList()

      if (this.state === 'tag_create') {
        InputDialogCard({ title: 'New tag', top: 320,
          body: () => { this.createDialogBody() },
          actions: () => { this.createDialogActions() },
          onDismiss: () => this.go('tags_list') })
      }
      if (this.state === 'tag_rename') {
        InputDialogCard({ title: 'Rename tag', top: 320,
          body: () => { this.renameDialogBody() },
          actions: () => { this.renameDialogActions() },
          onDismiss: () => this.go('tags_list') })
      }
      if (this.state === 'tag_context') {
        BottomSheet({ header: this.contextHeader(), rows: this.contextRows(),
          topRadius: 0, rowHeight: 64,
          onPick: (index: number) => this.handleContext(this.contextRows()[index].label),
          onDismiss: () => this.go('tags_list') })
      }
      if (this.state === 'tags_sort') {
        PopupMenu({ rows: this.sortRows(), top: 16, menuWidthPct: 60, rowHeight: 56,
          onPick: (index: number) => this.applySort(index),
          onDismiss: () => this.go('tags_list') })
      }
    }
    .width('100%').height('100%')
  }

  private contextHeader(): string {
    const tags: TagItem[] = this.tags();
    for (let i = 0; i < tags.length; i++) {
      if (tags[i].id === this.contextTagId) return tags[i].name;
    }
    return '';
  }

  private handleContext(label: string): void {
    const id: number = this.contextTagId;
    if (label === 'Rename tag') {
      this.renameTargetId = id;
      this.renameDraft = this.contextHeader();
      this.go('tag_rename');
      return;
    }
    if (label === 'Delete') {
      this.app().deleteTag(id);
      this.notify('Tag deleted');
      this.go('tags_list');
      return;
    }
    if (label === 'Select more…') {
      this.notify('Selection mode not supported for tags');
      this.go('tags_list');
      return;
    }
  }
}
