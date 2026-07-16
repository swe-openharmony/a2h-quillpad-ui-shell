import { Style } from './Style';

export interface MenuRow {
  label: string;
  icon?: Resource;
  trailing?: 'none' | 'radio' | 'checkbox';
  checked?: boolean;
  enabled?: boolean;
}

@Component
export struct PopupMenu {
  @Prop rows: MenuRow[];
  @Prop top: number = 20;
  @Prop alignRight: boolean = true;
  @Prop menuWidthPct: number = 72;
  @Prop rowHeight: number = 52;
  onPick: (i: number) => void = () => {};
  onDismiss: () => void = () => {};

  private listHeight(): number {
    return this.rows.length * this.rowHeight;
  }

  private menuWidthPctStr(): string {
    return this.menuWidthPct + '%';
  }

  private menuRightInsetPctStr(): string {
    return (100 - this.menuWidthPct - 2) + '%';
  }

  @Builder private trailingIndicator(row: MenuRow) {
    if (row.trailing === 'checkbox') {
      Stack() {
        Row()
          .width(20)
          .height(20)
          .border({ width: 2, color: Style.textSecondary, radius: 2 })
          .backgroundColor('#FFFFFF')
        if (row.checked) {
          Image($r('app.media.ic_box_checked'))
            .width(16)
            .height(16)
            .fillColor(Style.accent)
        }
      }
      .width(28)
      .height(28)
    } else if (row.trailing === 'radio') {
      Stack() {
        Row()
          .width(20)
          .height(20)
          .border({ width: 2, color: row.checked ? Style.accent : '#757983', radius: 10 })
          .backgroundColor('#FFFFFF')
        if (row.checked) {
          Circle({ width: 10, height: 10 })
            .fill(Style.accent)
        }
      }
      .width(28)
      .height(28)
    }
  }

  @Builder private menuRowBody(r: MenuRow, idx: number) {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Row() {
        if (r.icon) {
          Image(r.icon)
            .width(22)
            .height(22)
            .fillColor(Style.icon)
            .margin({ right: 20 })
        }
        Text(r.label)
          .fontSize(16)
          .fontColor(Style.textPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
        if (r.trailing && r.trailing !== 'none') {
          this.trailingIndicator(r)
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: r.icon ? 18 : 22, right: 18 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(this.rowHeight)
    .key('menu_action_' + r.label)
    .enabled(r.enabled !== false)
    .backgroundColor('#FFFFFF')
    .borderRadius(0)
    .padding(0)
    .onClick(() => this.onPick(idx))
  }

  build() {
    Stack() {
      Column()
        .width('100%').height('100%')
        .backgroundColor('#00000000')
        .onClick(() => this.onDismiss())

      Column() {
        Column() {
          ForEach(this.rows, (r: MenuRow, idx: number) => {
            this.menuRowBody(r, idx)
          }, (r: MenuRow) => r.label)
        }
        .width('100%')
        .height(this.listHeight())
      }
      .width(this.menuWidthPctStr())
      .backgroundColor('#FFFFFF')
      .borderRadius(4)
      .shadow({ radius: 14, color: '#33000000', offsetY: 4 })
      .padding({ top: 4, bottom: 4 })
      .markAnchor({ x: '100%', y: 0 })
      .position({ x: this.alignRight ? '98%' : '2%', y: this.top })
    }
    .width('100%').height('100%')
  }
}

@Component
export struct DialogCard {
  @Prop title: string;
  @BuilderParam body?: () => void;
  @BuilderParam actions?: () => void;
  onDismiss: () => void = () => {};

  build() {
    Stack() {
      Column()
        .width('100%').height('100%')
        .backgroundColor('#52000000')
        .onClick(() => this.onDismiss())
      Column() {
        if (this.title && this.title.length > 0) {
          Text(this.title)
            .fontSize(20).fontColor(Style.textPrimary).fontWeight(FontWeight.Medium)
            .width('100%').margin({ bottom: 16 })
        }
        if (this.body) {
          this.body()
        }
        if (this.actions) {
          Row() { this.actions() }
            .width('100%').justifyContent(FlexAlign.End).margin({ top: 18 })
        }
      }
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .padding(24)
      .width('86%')
      .shadow({ radius: 16, color: '#44000000', offsetY: 4 })
    }
    .width('100%').height('100%')
    .alignContent(Alignment.Center)
  }
}

@Component
export struct InputDialogCard {
  @Prop title: string;
  @BuilderParam body?: () => void;
  @BuilderParam actions?: () => void;
  @Prop top: number = 320;
  onDismiss: () => void = () => {};

  build() {
    Stack() {
      Column()
        .width('100%').height('100%')
        .backgroundColor('#52000000')
        .onClick(() => this.onDismiss())
      Column() {
        if (this.title && this.title.length > 0) {
          Text(this.title)
            .fontSize(20).fontColor(Style.textPrimary).fontWeight(FontWeight.Medium)
            .width('100%').margin({ bottom: 16 })
        }
        if (this.body) {
          this.body()
        }
        if (this.actions) {
          Row() { this.actions() }
            .width('100%').justifyContent(FlexAlign.End).margin({ top: 18 })
        }
      }
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .padding(24)
      .width('86%')
      .shadow({ radius: 16, color: '#44000000', offsetY: 4 })
      .position({ x: '7%', y: this.top })
    }
    .width('100%').height('100%')
  }
}

@Component
export struct BottomSheet {
  @Prop header: string;
  @Prop rows: MenuRow[];
  @Prop fullHeight: boolean = false;
  @Prop topInset: number = 0;
  @Prop topRadius: number = 0;
  @Prop rowHeight: number = 56;
  onPick: (i: number) => void = () => {};
  onDismiss: () => void = () => {};

  private compactListHeight(): number {
    return this.rows.length * this.rowHeight;
  }

  private compactSheetHeight(): number {
    const headerHeight: number = this.header && this.header.length > 0 ? 80 : 0;
    return headerHeight + this.compactListHeight() + 24;
  }

  @Builder private sheetRows(expanded: boolean) {
    Column() {
      ForEach(this.rows, (r: MenuRow, idx: number) => {
        Button({ type: ButtonType.Normal, stateEffect: false }) {
          Row() {
            if (r.icon) {
              Image(r.icon)
                .width(24)
                .height(24)
                .fillColor(Style.icon)
                .margin({ right: 28 })
            }
            Text(r.label)
              .fontSize(16)
              .fontColor(Style.textPrimary)
              .layoutWeight(1)
              .textAlign(TextAlign.Start)
          }
          .width('100%')
          .height('100%')
          .padding({ left: 20, right: 20 })
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .height(this.rowHeight)
        .backgroundColor('#FFFFFF')
        .borderRadius(0)
        .padding(0)
        .onClick(() => this.onPick(idx))
      }, (r: MenuRow) => r.label)
    }
    .width('100%')
    .height(expanded ? '100%' : this.compactListHeight())
  }

  @Builder private sheetSurfaceFull() {
    Column() {
      if (this.header && this.header.length > 0) {
        Text(this.header)
          .fontSize(16)
          .fontColor(Style.textSecondary)
          .width('100%')
          .padding({ left: 20, right: 20, top: 24, bottom: 20 })
      }
      Column() {
        this.sheetRows(true)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: this.topRadius, topRight: this.topRadius })
    .padding({ bottom: 24 })
    .clip(true)
    .shadow({ radius: 16, color: '#33000000', offsetY: -2 })
  }

  @Builder private sheetSurfaceCompact() {
    Column() {
      if (this.header && this.header.length > 0) {
        Text(this.header)
          .fontSize(16)
          .fontColor(Style.textSecondary)
          .width('100%')
          .padding({ left: 20, right: 20, top: 24, bottom: 20 })
      }
      this.sheetRows(false)
    }
    .width('100%')
    .height(this.compactSheetHeight())
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: this.topRadius, topRight: this.topRadius })
    .padding({ bottom: 24 })
    .clip(true)
    .shadow({ radius: 16, color: '#33000000', offsetY: -2 })
  }

  build() {
    if (this.fullHeight) {
      Stack({ alignContent: Alignment.Top }) {
        Column()
          .width('100%').height('100%')
          .backgroundColor('#52000000')
          .onClick(() => this.onDismiss())

        Column() {
          this.sheetSurfaceFull()
        }
        .width('100%')
        .height('100%')
      }
      .width('100%').height('100%')
    } else {
      Stack({ alignContent: Alignment.Bottom }) {
        Column()
          .width('100%').height('100%')
          .backgroundColor('#52000000')
          .onClick(() => this.onDismiss())

        Column() {
          this.sheetSurfaceCompact()
        }
        .width('100%')
      }
      .width('100%').height('100%')
    }
  }
}
