import { Style } from './Style';

// Reusable toolbar icon button (tinted SVG from converted media resources).
@Component
export struct IconButton {
  @Prop icon: Resource;
  @Prop tint: string = Style.icon;
  @Prop iconSize: number = Style.iconSize;
  @Prop keyId: string = '';
  onTap: () => void = () => {};

  build() {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      Image(this.icon)
        .width(this.iconSize)
        .height(this.iconSize)
        .fillColor(this.tint)
        .objectFit(ImageFit.Contain)
    }
    .backgroundColor(Color.Transparent)
    .width(44)
    .height(44)
    .key(this.keyId)
    .onClick(() => this.onTap())
  }
}

// Standard top app bar: leading nav icon + title + trailing actions slot.
@Component
export struct TopBar {
  @Prop leading: Resource;
  @Prop title: string;
  @Prop bg: string = Style.bg;
  @Prop titleColor: string = Style.textPrimary;
  @Prop titleBold: boolean = true;
  @Prop leadingTint: string = Style.icon;
  onLeading: () => void = () => {};
  @BuilderParam actions: () => void = this.emptyActions;

  @Builder emptyActions() {}

  build() {
    Row() {
      IconButton({ icon: this.leading, tint: this.leadingTint, onTap: () => this.onLeading() })
        .margin({ left: 4, right: 8 })
        .key('toolbar_nav')
      Text(this.title)
        .fontSize(Style.titleSize)
        .fontColor(this.titleColor)
        .fontWeight(this.titleBold ? FontWeight.Medium : FontWeight.Normal)
        .layoutWeight(1)
      Row() { this.actions() }.key('toolbar_actions')
    }
    .width('100%')
    .height(Style.toolbarHeight)
    .padding({ right: 4 })
    .backgroundColor(this.bg)
    .alignItems(VerticalAlign.Center)
  }
}

// Tag chip pill (e.g. "# todo").
@Component
export struct TagChip {
  @Prop label: string;
  build() {
    Text('# ' + this.label)
      .fontSize(13)
      .fontColor(Style.textPrimary)
      .border({ width: 1, color: Style.chipBorder, radius: 16 })
      .padding({ left: 12, right: 12, top: 5, bottom: 5 })
      .margin({ right: 6, top: 4 })
  }
}
