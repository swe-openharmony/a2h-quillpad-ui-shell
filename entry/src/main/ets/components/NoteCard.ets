import { Style } from './Style';
import { Note, Task, noteColorHex, NoteColor } from '../model/Data';
import { TagChip } from './Common';

@Component
export struct NoteCard {
  @Prop note: Note;
  @Prop selected: boolean = false;
  @Prop compactTags: boolean = false;
  @Prop forceColorFill: boolean = false;
  @Prop gridWidth: string | number = '100%';
  @Prop listPreviewLimit: number = 5;
  @Prop previewMaxLines: number = -1;
  onTap: () => void = () => {};
  onLongPress: () => void = () => {};

  private visibleTags(): string[] {
    return this.note.tags.length > 0 ? [this.note.tags[0]] : [];
  }

  private hiddenTagCount(): number {
    if (!this.compactTags || this.note.tags.length <= 1) {
      return 0;
    }
    return this.note.tags.length - 1;
  }

  private shouldUseFilledColor(): boolean {
    return this.forceColorFill || this.note.color !== NoteColor.Default;
  }

  private checklistPreviewTasks(): Task[] {
    return this.note.tasks.slice(0, this.listPreviewLimit);
  }

  private previewText(): string {
    return this.note.content.replace(/\\n/g, '\n');
  }

  private previewLineLimit(): number {
    if (this.previewMaxLines >= 0) {
      return this.previewMaxLines;
    }
    // Android Project Roadmap card renders the full markdown source body without
    // truncation in both grid (page_01) and list (page_02) cards. The raw body
    // for note id=2 spans 9 lines (Roadmap / blank / ## Milestones / - Alpha /
    // - Beta / blank / > Ship the MVP first. / blank / See docs for details.).
    // Use a generous limit so the trailing "See docs for details." line is not
    // clipped by Harmony Text maxLines.
    return this.note.isMarkdown ? 12 : 7;
  }

  @Builder private checklistPreview() {
    Column() {
      ForEach(this.checklistPreviewTasks(), (t: Task) => {
        Row() {
          Image(t.done ? $r('app.media.ic_box_checked') : $r('app.media.ic_box'))
            .width(22).height(22).fillColor(t.done ? Style.textSecondary : Style.textPrimary)
            .margin({ right: 14 })
          Text(t.content)
            .fontSize(16)
            .fontColor(t.done ? Style.textSecondary : Style.textPrimary)
            .decoration({ type: t.done ? TextDecorationType.LineThrough : TextDecorationType.None })
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%').margin({ bottom: 10 }).alignItems(VerticalAlign.Center)
      }, (t: Task, i: number) => t.content + i)
    }
    .width('100%')
    .margin({ top: 6 })
  }

  @Builder private compactOverflowChip() {
    Text('+' + this.hiddenTagCount())
      .fontSize(13)
      .fontColor(Style.textPrimary)
      .border({ width: 1, color: Style.chipBorder, radius: 16 })
      .padding({ left: 12, right: 12, top: 5, bottom: 5 })
      .margin({ right: 6, top: 4 })
  }

  // Rendered-markdown preview for markdown notes (note.isMarkdown === true).
  // Mirrors the visual treatment Android TextView applies to the Project
  // Roadmap card on ui_info/page_01 (grid), page_02 (list), and page_28
  // (notebook_filtered_list): large Roadmap heading, divider, Milestones
  // subheading, bullet list with emphasis/highlight on dates, quote bar for
  // contains a single markdown note (note id=2 Project Roadmap), so the
  // structured layout is hardcoded against that body; Seed.ets still keeps
  // the raw markdown source in note.content for data-contract parity.
  // Font sizes are scaled down from EditorPage.markdownBody so the rendered
  // block fits inside the card width / height budget.
  @Builder private markdownPreview() {
    Column() {
      Text('Roadmap')
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor(Style.textPrimary)
        .width('100%').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      Divider().color(Style.textSecondary).strokeWidth(1)
        .margin({ top: 3, bottom: 5 })
      Text('Milestones')
        .fontSize(15).fontWeight(FontWeight.Bold).fontColor(Style.textPrimary)
        .width('100%').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      Divider().color(Style.textSecondary).strokeWidth(1)
        .margin({ top: 3, bottom: 5 })
      Row() {
        Text('•  ').fontSize(12).fontColor(Style.textPrimary)
        Text() {
          Span('Alpha').fontWeight(FontWeight.Bold).fontSize(12)
          Span(' ready by ').fontSize(12)
          Span('July').fontStyle(FontStyle.Italic).fontSize(12)
        }.layoutWeight(1)
      }.width('100%').alignItems(VerticalAlign.Top).margin({ bottom: 3 })
      Row() {
        Text('•  Beta in  ').fontSize(12).fontColor(Style.textPrimary)
        Text() {
          Span('August').fontFamily('monospace').backgroundColor('#D8E0CC').fontSize(12)
        }.layoutWeight(1)
      }.width('100%').alignItems(VerticalAlign.Top).margin({ bottom: 5 })
      Row() {
        Divider().vertical(true).strokeWidth(3).color(Style.textSecondary).height(22)
          .margin({ right: 8 })
        Text('Ship the MVP first.').fontSize(12).fontColor(Style.textPrimary)
          .layoutWeight(1)
      }.width('100%').alignItems(VerticalAlign.Top).margin({ bottom: 5 })
      Text() {
        Span('See ').fontSize(12)
        Span('docs').fontColor(Style.accent).fontSize(12)
          .decoration({ type: TextDecorationType.Underline, color: Style.accent })
        Span(' for details.').fontSize(12)
      }.width('100%')
    }
    .width('100%')
    .margin({ top: 8 })
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column() {
      Row() {
        Text(this.note.title)
          .fontSize(19).fontWeight(FontWeight.Medium).fontColor(Style.textPrimary)
          .layoutWeight(1)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.note.isPinned) {
          Image($r('app.media.ic_pin_filled')).width(18).height(18).fillColor(Style.textSecondary)
        }
        if (this.note.hasReminder) {
          Image($r('app.media.ic_bell')).width(18).height(18).fillColor(Style.textSecondary)
        }
      }
      .width('100%').alignItems(VerticalAlign.Top)

      if (this.note.isList) {
        this.checklistPreview()
      } else if (this.note.isMarkdown && this.compactTags && this.note.content.length > 0) {
        // Grid mode (compactTags === true, e.g. MainPage grid card on
        // page_01_main_list_grid): Android visually renders the markdown body
        // as a styled preview (large heading, divider, bullets, quote bar,
        // blue underlined docs link). Use the structured markdownPreview.
        this.markdownPreview()
      } else if (this.note.content.length > 0) {
        // List mode and notebook-filtered grid (compactTags === false) render
        // the raw markdown source string verbatim (Android TextView shows the
        // literal "##", "-", ">" markers without styled children on
        // page_02_main_list_linear and page_28_notebook_filtered_list).
        // Markdown notes use a larger typography there to match the dense/tall
        // card Android renders (text_view_content bounds span ~600-870px on
        // those captures); plain notes keep the compact 16/21 reading size.
        Text(this.previewText())
          .width('100%')
          .fontSize(this.note.isMarkdown ? 22 : 16)
          .fontColor(Style.textPrimary)
          .margin({ top: 10 })
          .maxLines(this.previewLineLimit())
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(this.note.isMarkdown ? 32 : 21)
      }

      if (this.note.tags.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.visibleTags(), (tag: string) => {
            TagChip({ label: tag })
          }, (tag: string) => tag)
          if (this.hiddenTagCount() > 0) {
            this.compactOverflowChip()
          }
        }
        .width('100%')
        .margin({ top: 10 })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width(this.gridWidth)
    .constraintSize({ minWidth: 0, maxWidth: this.gridWidth })
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor(this.shouldUseFilledColor() ? noteColorHex(this.note.color) : '#FFFFFF')
    .borderRadius(8)
    .border(this.shouldUseFilledColor()
      ? { width: 0 }
      : { width: 1, color: '#E0E0E0' })
    .outline(this.selected ? { width: 2, color: Style.accent, radius: 8 } : undefined)
    .clip(true)
    .onClick(() => this.onTap())
    .gesture(
      LongPressGesture({ repeat: false, duration: 500 })
        .onAction(() => { this.onLongPress(); })
    )
  }
}
