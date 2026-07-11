import { Style } from '../components/Style';
import { IconButton, TagChip } from '../components/Common';
import { PopupMenu, DialogCard, InputDialogCard, MenuRow } from '../components/Overlays';
import { Note, Task, noteColorHex, NoteColor } from '../model/Data';
import { AppState, EditorMode } from '../state/AppState';
import { promptAction } from '@kit.ArkUI';

@Component
export struct EditorPage {
  @Prop state: string;
  go: (route: string) => void = () => {};

  // linkUrlDraft, createTitleDraft, createContentDraft, rawMarkdownBody,
  // colorDialogBody, InputDialogCard usage.
  @State private markdownDraft: string = '# Roadmap\n\n## Milestones\n- **Alpha** ready by *July*\n- Beta in `August`\n\n> Ship the MVP first.\n\nSee [docs](https://example.com) for details.';
  @State private createTitleDraft: string = '';
  @State private createContentDraft: string = '';
  @State private linkTextDraft: string = '';
  @State private linkUrlDraft: string = '';
  @State private markdownEnabled: boolean = true;
  @State private isEditMode: boolean = false;
  @State private colorPicked: NoteColor = NoteColor.Green;
  // Track which note opened the editor so overflow/color/insert-link sub-
  // states (which lose the :id param) still resolve the same note. Set in
  // handleBack/go transitions and read by resolveNote when the state does
  // not carry an id.
  @State private overflowNoteId: number = 0;

  @StorageLink('qp_notes_version') notesVersion: number = 0;

  private app(): AppState { return AppState.getInstance(); }

  private overflowRows(): MenuRow[] {
    const convertLabel: string = this.resolveNote().isList ? 'Convert to note' : 'Convert to list';
    return [
      { label: convertLabel },
      { label: 'Archive' },
      { label: 'Delete' },
      { label: 'Hide', trailing: 'checkbox', checked: false },
      { label: 'Screen always on', trailing: 'checkbox', checked: false },
      { label: 'Do not sync', trailing: 'checkbox', checked: false },
      { label: 'Change color' },
      { label: 'Disable markdown' },
      { label: 'Attach files' },
      { label: 'Record audio' },
      { label: 'Take a photo' },
      { label: 'Tags' }
    ];
  }
  private colorRows(): MenuRow[] {
    const list: NoteColor[] = [
      NoteColor.Green, NoteColor.Teal, NoteColor.Cyan, NoteColor.Blue,
      NoteColor.Purple, NoteColor.Pink, NoteColor.Brown,
    ];
    const rows: MenuRow[] = [];
    for (let i = 0; i < list.length; i++) {
      rows.push({ label: this.colorName(list[i]), trailing: 'radio', checked: list[i] === this.colorPicked });
    }
    return rows;
  }
  private colorName(c: NoteColor): string {
    switch (c) {
      case NoteColor.Red: return 'Red';
      case NoteColor.Orange: return 'Orange';
      case NoteColor.Yellow: return 'Yellow';
      case NoteColor.Green: return 'Green';
      case NoteColor.Teal: return 'Teal';
      case NoteColor.Cyan: return 'Cyan';
      case NoteColor.Blue: return 'Blue';
      case NoteColor.Purple: return 'Purple';
      case NoteColor.Pink: return 'Pink';
      case NoteColor.Brown: return 'Brown';
      case NoteColor.Gray: return 'Gray';
      default: return 'Default';
    }
  }
  private nameToColor(name: string): NoteColor {
    if (name === 'Red') return NoteColor.Red;
    if (name === 'Orange') return NoteColor.Orange;
    if (name === 'Yellow') return NoteColor.Yellow;
    if (name === 'Green') return NoteColor.Green;
    if (name === 'Teal') return NoteColor.Teal;
    if (name === 'Cyan') return NoteColor.Cyan;
    if (name === 'Blue') return NoteColor.Blue;
    if (name === 'Purple') return NoteColor.Purple;
    if (name === 'Pink') return NoteColor.Pink;
    if (name === 'Brown') return NoteColor.Brown;
    if (name === 'Gray') return NoteColor.Gray;
    return NoteColor.Default;
  }

  // Resolve the current note from AppState (live).
  resolveNote(): Note {
    const app: AppState = this.app();
    if (this.state === 'editor_create') return this.createNote();
    if (this.state.startsWith('editor_view:')) {
      const id: number = this.parseIntSafe(this.state.substring('editor_view:'.length));
      // Remember the note id so editor_overflow / editor_color_picker /
      // editor_insert_link (which drop the :id param) still resolve it.
      this.overflowNoteId = id;
      const n: Note | null = app.noteById(id);
      return n === null ? this.fallbackNote() : (n as Note);
    }
    if (this.state.startsWith('editor_edit:')) {
      const id: number = this.parseIntSafe(this.state.substring('editor_edit:'.length));
      this.overflowNoteId = id;
      const n: Note | null = app.noteById(id);
      return n === null ? this.fallbackNote() : (n as Note);
    }
    if (this.state.startsWith('editor_checklist')) {
      // A text note converted through editor_overflow must keep its original
      // identity; id=3 is only the default seeded checklist fallback.
      if (this.overflowNoteId > 0) {
        const converted: Note | null = app.noteById(this.overflowNoteId);
        if (converted !== null) return converted as Note;
      }
      const n: Note | null = app.noteById(3);
      return n === null ? this.fallbackNote() : (n as Note);
    }
    // editor_overflow / editor_color_picker / editor_insert_link carry no
    // :id param. Prefer the remembered overflowNoteId (set when we left
    // only when no explicit note was opened.
    if (this.overflowNoteId > 0) {
      const n2: Note | null = app.noteById(this.overflowNoteId);
      if (n2 !== null) return n2 as Note;
    }
    if (this.isMarkdownContext()) {
      const n: Note | null = app.noteById(2);
      return n === null ? this.fallbackNote() : (n as Note);
    }
    if (this.state === 'editor_plain_view') {
      const n: Note | null = app.noteById(1);
      return n === null ? this.fallbackNote() : (n as Note);
    }
    const fallback: Note | null = app.noteById(1);
    return fallback === null ? this.fallbackNote() : (fallback as Note);
  }

  private fallbackNote(): Note {
    return this.createNote();
  }

  private parseIntSafe(s: string): number {
    const v: number = parseInt(s, 10);
    return isNaN(v) ? 0 : v;
  }

  // Builder for a brand new note (NOT persisted until content is non-empty).
  createNote(): Note {
    return {
      id: 0,
      title: '',
      content: '',
      isList: false,
      tasks: [],
      color: NoteColor.Default,
      notebook: null,
      tags: [],
      isPinned: false,
      hasReminder: false,
      isMarkdown: false,
      createdText: 'Created at June 29 2026, 12:11',
      modifiedText: 'Last modified at June 29 2026, 12:11',
      archived: false,
      deleted: false
    };
  }

  isMarkdownContext(): boolean {
    return this.state === 'editor_markdown_view'
      || this.state === 'editor_markdown_edit'
      || this.state === 'editor_overflow'
      || this.state === 'editor_color_picker'
      || this.state === 'editor_insert_link';
  }

  isEdit(): boolean {
    return this.state === 'editor_markdown_edit' || this.state === 'editor_checklist_edit'
      || this.state === 'editor_create' || this.state === 'editor_insert_link'
      || this.state.indexOf('editor_edit:') === 0;
  }

  isCreate(): boolean { return this.state === 'editor_create'; }

  usesMarkdownEditorSurface(): boolean {
    return this.state === 'editor_markdown_edit'
      || this.state === 'editor_insert_link'
      || this.state === 'editor_create';
  }

  private persistCreate(): void {
    // Persist the in-progress create-note draft when the user leaves the editor.
    if (!this.isCreate()) return;
    const title: string = this.createTitleDraft.trim();
    const body: string = this.createContentDraft.trim();
    if (title.length === 0 && body.length === 0) return; // discard
    const app: AppState = this.app();
    const n: Note = app.createNote();
    n.title = title;
    n.content = body;
    n.isMarkdown = true;
    app.bumpVersion();
  }

  private commitMarkdownDraft(): void {
    // Persisting editor content is implementation work.
  }

  private notify(msg: string): void {
    try {
      promptAction.showToast({ message: msg, duration: 1500 });
    } catch (e) {
      // ignore
    }
  }

  @Builder notebookChip(name: string) {
    Row() {
      Image($r('app.media.ic_notebook')).width(18).height(18).fillColor(Style.textPrimary).margin({ right: 8 })
      Text(name).fontSize(16).fontColor(Style.textPrimary).fontWeight(FontWeight.Medium)
      Image($r('app.media.ic_notebook_swap')).width(16).height(16).fillColor(Style.textPrimary).margin({ left: 8 })
    }
    .border({ width: 1, color: Style.chipBorder, radius: 20 })
    .padding({ left: 14, right: 14, top: 6, bottom: 6 })
  }

  @Builder editorToolbar(note: Note) {
    Row() {
      IconButton({ icon: $r('app.media.ic_back'), onTap: () => this.handleBack() })
        .margin({ left: 4, right: 8 })
      this.notebookChip(note.notebook === null ? 'No Notebook' : note.notebook)
      Blank()
      IconButton({ icon: note.isPinned ? $r('app.media.ic_pin_filled') : $r('app.media.ic_pin'),
        keyId: 'editor_pin', onTap: () => { if (note.id > 0) { this.app().togglePinned(note.id); this.notify(note.isPinned ? 'Unpinned' : 'Pinned'); } } })
      IconButton({ icon: $r('app.media.ic_bell'), keyId: 'editor_reminder', onTap: () => {
        if (note.id > 0) {
          this.app().updateNote(note.id, (_n: Note) => {});
        }
      } })
      IconButton({ icon: $r('app.media.ic_more_vert'), keyId: 'editor_more', onTap: () => this.go('editor_overflow') })
    }
    .width('100%').height(Style.toolbarHeight).padding({ right: 4 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder dateFooter(note: Note) {
    Text(note.createdText + '\n' + note.modifiedText)
      .fontSize(13).fontColor(Style.textSecondary).fontStyle(FontStyle.Italic)
      .margin({ top: 20 })
      .key('editor_date_footer')
  }

  @Builder checklistBody(note: Note) {
    Column() {
      Row() {
        Image($r('app.media.ic_add')).width(24).height(24).fillColor(Style.textPrimary).margin({ right: 20 })
        Text('Task').fontSize(16).fontColor(Style.textHint)
      }.width('100%').height(48).alignItems(VerticalAlign.Center).key('checklist_add_task')
      .onClick(() => {
        if (note.id > 0) {
          this.app().addTaskAt(note.id, 0, 'New task');
        }
      })
      ForEach(note.tasks, (t: Task, index: number) => {
        Row() {
          Image(t.done ? $r('app.media.ic_box_checked') : $r('app.media.ic_box'))
            .width(24).height(24).fillColor(t.done ? Style.textSecondary : Style.textPrimary).margin({ right: 20 })
            .onClick(() => {
              if (note.id > 0) this.app().toggleTask(note.id, index);
            })
            .key('task_checkbox_' + index)
          Text(t.content).fontSize(18)
            .fontColor(t.done ? Style.textSecondary : Style.textPrimary)
            .decoration({ type: t.done ? TextDecorationType.LineThrough : TextDecorationType.None })
            .layoutWeight(1)
            .key('task_content_' + index)
          Image($r('app.media.ic_handle')).width(22).height(22).fillColor(Style.textSecondary)
            .onClick(() => {
              if (note.id > 0) {
                this.app().removeTask(note.id, index);
                this.notify('Task removed');
              }
            })
            .key('task_handle_' + index)
        }.width('100%').height(56).alignItems(VerticalAlign.Center).key('task_row_' + index)
          .accessibilityText((t.done ? 'Checked: ' : 'Unchecked: ') + t.content)
      }, (t: Task, i: number) => t.content + i + '_' + this.notesVersion)
    }.margin({ top: 8 })
  }

  @Builder markdownBody(note: Note) {
    Column() {
      Text('Roadmap').fontSize(34).fontWeight(FontWeight.Bold).fontColor(Style.textPrimary).width('100%')
      Divider().color(Style.textSecondary).margin({ top: 4, bottom: 16 })
      Text('Milestones').fontSize(28).fontWeight(FontWeight.Bold).fontColor(Style.textPrimary).width('100%')
      Divider().color(Style.textSecondary).margin({ top: 4, bottom: 16 })
      Text() {
        Span('•  ').fontColor(Style.textPrimary)
        Span('Alpha').fontWeight(FontWeight.Bold)
        Span(' ready by ')
        Span('July').fontStyle(FontStyle.Italic)
      }.fontSize(18).width('100%').margin({ bottom: 6 })
      Text() {
        Span('•  Beta in  ')
        Span('August').fontFamily('monospace').backgroundColor('#D8E0CC')
      }.fontSize(18).width('100%').margin({ bottom: 14 })
      Row() {
        Divider().vertical(true).strokeWidth(3).color(Style.textSecondary).height(40).margin({ right: 14 })
        Text('Ship the MVP first.').fontSize(18).fontColor(Style.textPrimary)
      }.margin({ bottom: 14 })
      Text() {
        Span('See ')
        Span('docs').fontColor(Style.accent).decoration({ type: TextDecorationType.Underline, color: Style.accent })
        Span(' for details.')
      }.fontSize(18).width('100%')
    }.alignItems(HorizontalAlign.Start).margin({ top: 8 })
  }

  // to the markdownDraft state (preserved) and persist when leaving edit mode.
  @Builder rawMarkdownBody() {
    TextInput({ text: this.markdownDraft, placeholder: '' })
      .fontSize(18)
      .fontColor(Style.textPrimary)
      .fontFamily('monospace')
      .width('100%')
      .backgroundColor(Color.Transparent)
      .padding({ left: 0, right: 0, top: 8, bottom: 8 })
      .defaultFocus(true)
      .enableKeyboardOnFocus(true)
      .showUnderline(false)
      .key('editor_content')
      .onChange((value: string) => {
        this.markdownDraft = value
      })
  }

  @Builder createEditBody(note: Note) {
    Column() {
      TextInput({ text: this.createTitleDraft, placeholder: 'Title' })
        .fontSize(26)
        .fontColor(Style.textPrimary)
        .width('100%')
        .backgroundColor(Color.Transparent)
        .showUnderline(false)
        .padding({ left: 0, right: 0, top: 8, bottom: 0 })
        .key('editor_title')
        .onChange((value: string) => { this.createTitleDraft = value })

      TextInput({ text: this.createContentDraft, placeholder: 'Take a note!' })
        .fontSize(18)
        .fontColor(Style.textPrimary)
        .width('100%')
        .backgroundColor(Color.Transparent)
        .showUnderline(false)
        .defaultFocus(true)
        .enableKeyboardOnFocus(true)
        .padding({ left: 0, right: 0, top: 20, bottom: 8 })
        .key('editor_content')
        .onChange((value: string) => { this.createContentDraft = value })

      this.dateFooter(note)
    }
    .alignItems(HorizontalAlign.Start)
  }

  @Builder mdToolbar() {
    Row() {
      IconButton({ icon: $r('app.media.ic_bold'), keyId: 'md_bold', onTap: () => this.wrapSelection('**') })
      IconButton({ icon: $r('app.media.ic_italics'), keyId: 'md_italic', onTap: () => this.wrapSelection('*') })
      IconButton({ icon: $r('app.media.ic_strikethrough'), keyId: 'md_strike', onTap: () => this.wrapSelection('~~') })
      IconButton({ icon: $r('app.media.ic_header'), keyId: 'md_heading', onTap: () => this.cycleHeading() })
      IconButton({ icon: $r('app.media.ic_quote'), keyId: 'md_quote', onTap: () => this.prefixLine('> ') })
      IconButton({ icon: $r('app.media.ic_highlight'), keyId: 'md_highlight', onTap: () => this.wrapSelection('==') })
      IconButton({ icon: $r('app.media.ic_code'), keyId: 'md_code', onTap: () => this.wrapSelection('`') })
      IconButton({ icon: $r('app.media.ic_link'), keyId: 'md_link', onTap: () => this.go('editor_insert_link') })
    }
    .width('100%').height(52).padding({ left: 8, right: 8 })
    .justifyContent(FlexAlign.SpaceBetween)
    .backgroundColor('#F0F0F0')
  }

  // Toolbar controls are mounted by the shell; their text mutations are not.
  private wrapSelection(_delim: string): void {
  }
  private cycleHeading(): void {
  }
  private prefixLine(_prefix: string): void {
  }

  bgColor(): string {
    const note: Note = this.resolveNote();
    return note.color === NoteColor.Default ? '#FFFFFF' : noteColorHex(note.color);
  }

  handleOverflowPick(index: number): void {
    const label: string = this.overflowRows()[index].label;
    const note: Note = this.resolveNote();
    const id: number = note.id;
    if (label === 'Change color') {
      this.colorPicked = note.color === NoteColor.Default ? NoteColor.Green : note.color;
      this.go('editor_color_picker');
      return;
    }
    if (label === 'Archive') {
      if (id > 0) {
        this.app().selectedIds = [id];
        this.notify(this.app().archiveSelected());
      }
      this.go('main_grid_default');
      return;
    }
    if (label === 'Delete') {
      if (id > 0) {
        this.app().selectedIds = [id];
        this.notify(this.app().deleteSelected());
      }
      this.go('main_grid_default');
      return;
    }
    if (label === 'Hide') {
      if (id > 0) this.app().toggleHidden(id);
      this.notify('Hide toggled');
      return;
    }
    if (label === 'Screen always on') {
      if (id > 0) this.app().updateNote(id, (_n: Note) => {});
      return;
    }
    if (label === 'Do not sync') {
      if (id > 0) this.app().toggleLocalOnly(id);
      this.notify('Do-not-sync toggled');
      return;
    }
    if (label === 'Convert to list') {
      if (id > 0) {
        this.app().convertToList(id);
        this.go('editor_checklist_edit');
      }
      return;
    }
    if (label === 'Convert to note') {
      if (id > 0) {
        this.app().convertToText(id);
        const converted: Note | null = this.app().noteById(id);
        this.go(converted !== null && (converted as Note).isMarkdown
          ? 'editor_markdown_edit' : 'editor_edit:' + id);
      }
      return;
    }
    if (label === 'Disable markdown' || label === 'Enable markdown') {
      if (id > 0) this.app().toggleMarkdown(id);
      return;
    }
    if (label === 'Tags') {
      if (id > 0) {
        this.app().tagAssignmentNoteId = id;
        this.app().bumpVersion();
        this.go('tags_assignment');
      }
      return;
    }
    if (label === 'Attach files' || label === 'Record audio' || label === 'Take a photo') {
      this.notify('Not supported in shell');
      return;
    }
  }

  handleBack(): void {
    if (this.isCreate()) {
      this.persistCreate();
    } else if (this.state === 'editor_markdown_edit' || this.state === 'editor_insert_link') {
      this.commitMarkdownDraft();
    }
    this.go('main_grid_default');
  }

  @Builder colorDialogBody() {
    Column() {
      ForEach(this.colorRows(), (row: MenuRow) => {
        Row() {
          Stack() {
            Row()
              .width(20)
              .height(20)
              .border({ width: 2, color: row.checked ? Style.accent : '#757983', radius: 10 })
              .backgroundColor('#FFFFFF')
            if (row.checked) {
              Circle({ width: 10, height: 10 }).fill(Style.accent)
            }
          }
          .width(28)
          .height(28)
          .margin({ right: 20 })
          Text(row.label)
            .fontSize(18)
            .fontColor(Style.textSecondary)
            .layoutWeight(1)
        }
        .width('100%')
        .height(56)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.colorPicked = this.nameToColor(row.label);
          const note: Note = this.resolveNote();
          if (note.id > 0) {
            this.app().setNoteColor(note.id, this.colorPicked);
          }
        })
      }, (row: MenuRow) => row.label)
    }
    .width('100%')
  }

  @Builder doneOnlyAction(backState: string) {
    Text('DONE!').fontSize(15).fontColor(Style.accent).fontWeight(FontWeight.Medium)
      .onClick(() => this.go(backState))
  }

  @Builder linkDialogBody() {
    Column() {
      TextInput({ text: this.linkTextDraft, placeholder: 'Text' })
        .backgroundColor('#FFFFFF')
        .borderColor(Style.divider).borderWidth({ bottom: 1 }).borderRadius(0)
        .margin({ bottom: 12 })
        .defaultFocus(true)
        .enableKeyboardOnFocus(true)
        .onChange((value: string) => { this.linkTextDraft = value })
      TextInput({ text: this.linkUrlDraft, placeholder: 'URL' })
        .backgroundColor('#FFFFFF')
        .borderColor(Style.divider).borderWidth({ bottom: 1 }).borderRadius(0)
        .onChange((value: string) => { this.linkUrlDraft = value })
      Row() {
        Blank()
        Text('CANCEL').fontSize(15).fontColor(Style.accent).fontWeight(FontWeight.Medium)
          .margin({ right: 24 }).onClick(() => this.go('editor_markdown_edit'))
        Text('INSERT').fontSize(15).fontColor(Style.accent).fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.go('editor_markdown_edit');
          })
      }.width('100%').margin({ top: 18 })
    }
  }


  // Generic editable surface for a non-markdown, non-checklist note opened
  // via editor_edit:<id>. Renders a TextInput title + TextInput content so
  // business specs that drive editor_content / editor_title work on any
  @State private genericTitleDraft: string = '';
  @State private genericContentDraft: string = '';
  @Builder genericEditBody(note: Note) {
    Column() {
      TextInput({ text: this.genericTitleDraft.length > 0 ? this.genericTitleDraft : note.title,
                  placeholder: 'Title' })
        .fontSize(26)
        .fontColor(Style.textPrimary)
        .width('100%')
        .backgroundColor(Color.Transparent)
        .showUnderline(false)
        .padding({ left: 0, right: 0, top: 8, bottom: 0 })
        .key('editor_title')
        .onChange((value: string) => {
          this.genericTitleDraft = value;
          if (note.id > 0) this.app().setNoteTitle(note.id, value.trim());
        })

      TextInput({ text: this.genericContentDraft.length > 0 ? this.genericContentDraft : note.content,
                  placeholder: 'Take a note!' })
        .fontSize(18)
        .fontColor(Style.textPrimary)
        .width('100%')
        .backgroundColor(Color.Transparent)
        .showUnderline(false)
        .defaultFocus(true)
        .enableKeyboardOnFocus(true)
        .padding({ left: 0, right: 0, top: 20, bottom: 8 })
        .key('editor_content')
        .onChange((value: string) => {
          this.genericContentDraft = value;
          if (note.id > 0) this.app().setNoteContent(note.id, value);
        })

      this.dateFooter(note)
    }
    .alignItems(HorizontalAlign.Start)
  }

  isGenericEdit(): boolean {
    return this.state.indexOf('editor_edit:') === 0;
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        this.editorToolbar(this.resolveNote())
        Scroll() {
          Column() {
            if (this.isCreate()) {
              this.createEditBody(this.resolveNote())
            } else if (this.isGenericEdit()) {
              this.genericEditBody(this.resolveNote())
            } else if (this.usesMarkdownEditorSurface()) {
              this.rawMarkdownBody()
            } else {
              Text(this.resolveNote().title).fontSize(26).fontWeight(FontWeight.Bold).fontColor(Style.textPrimary)
                .width('100%').margin({ top: 8 })
              if (this.resolveNote().isList) {
                this.checklistBody(this.resolveNote())
              } else if (this.resolveNote().isMarkdown) {
                this.markdownBody(this.resolveNote())
              } else {
                Text(this.resolveNote().content).fontSize(18).fontColor(Style.textPrimary).width('100%').margin({ top: 16 })
                  .key('editor_body')
              }
              this.dateFooter(this.resolveNote())
              if (this.resolveNote().tags.length > 0) {
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(this.resolveNote().tags, (t: string) => { TagChip({ label: t }) }, (t: string) => t)
                }.margin({ top: 12 })
              }
            }
          }.alignItems(HorizontalAlign.Start).padding({ left: 16, right: 16 }).width('100%')
        }.layoutWeight(1).align(Alignment.TopStart)

        if (this.state === 'editor_markdown_edit' || this.state === 'editor_create' || this.state === 'editor_insert_link') {
          this.mdToolbar()
        }
      }
      .width('100%').height('100%').backgroundColor(this.bgColor())

      if (!this.isEdit() || this.state === 'editor_markdown_edit') {
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_preview')).width(26).height(26).fillColor(Color.White)
        }
        .width(60).height(60).backgroundColor(Style.fabBlue)
        .margin({ right: 18, bottom: this.state === 'editor_markdown_edit' ? 76 : 24 })
        .key('fab_change_mode')
        .onClick(() => {
          // so any note can enter edit mode and surface the editor_content
          // input + markdown toolbar the business specs drive).
          if (this.state === 'editor_markdown_view') {
            this.go('editor_markdown_edit');
          } else if (this.state === 'editor_markdown_edit') {
            this.go('editor_markdown_view');
          } else if (this.state.indexOf('editor_view:') === 0) {
            const id: string = this.state.substring('editor_view:'.length);
            // For a markdown note enter editor_markdown_edit (preserves the
            // markdown editor surface + toolbar); for any other note enter
            // editor_edit:<id> (a generic editable surface that still
            // resolves the same note via overflowNoteId).
            const n: Note | null = this.app().noteById(this.parseIntSafe(id));
            if (n !== null && (n as Note).isMarkdown) {
              this.overflowNoteId = (n as Note).id;
              this.go('editor_markdown_edit');
            } else {
              this.overflowNoteId = this.parseIntSafe(id);
              this.go('editor_edit:' + id);
            }
          } else if (this.state.indexOf('editor_edit:') === 0) {
            const id2: string = this.state.substring('editor_edit:'.length);
            this.go('editor_view:' + id2);
          } else if (this.state === 'editor_checklist_view') {
            this.go('editor_checklist_edit');
          } else if (this.state === 'editor_checklist_edit') {
            this.go('editor_checklist_view');
          }
        })
      }

      if (this.state === 'editor_overflow') {
        PopupMenu({ rows: this.overflowRows(), top: 20, menuWidthPct: 60, rowHeight: 52,
          onPick: (index: number) => this.handleOverflowPick(index),
          onDismiss: () => this.go('editor_markdown_view') })
      }
      if (this.state === 'editor_color_picker') {
        DialogCard({ title: 'Change color',
          body: () => { this.colorDialogBody() },
          actions: () => { this.doneOnlyAction('editor_markdown_view') },
          onDismiss: () => this.go('editor_markdown_view') })
      }
      if (this.state === 'editor_insert_link') {
        InputDialogCard({ title: 'Insert link', top: 360,
          body: () => { this.linkDialogBody() },
          onDismiss: () => this.go('editor_markdown_edit') })
      }
    }
    .width('100%').height('100%')
  }
}
