# Portrait to Sofubi Package

A Codex skill that turns one full-body portrait into a coordinated sofubi release:

1. a selectable pink blank, cyan blank, or painted dehara-style sofubi toy;
2. a rough crayon chibi illustration;
3. a clear-bag packaged product photo with a generated Japanese header-card title.

## Install

Copy this folder into your Codex skills directory:

```bash
cp -R portrait-to-sofubi-package ~/.codex/skills/
```

Restart Codex if the skill is not discovered immediately.

## Run

Upload one person photo and ask:

```text
使用 $portrait-to-sofubi-package 处理这张照片
```

The skill checks whether a complete head-to-feet person is visible, creates and shows a transparent cutout, then pauses for a choice:

```text
粉色素体 / 青色素体 / dehara
```

## Outputs

Each run creates a new workspace folder containing:

- `00-person-cutout.png`
- `01-sofubi-toy.png`
- `02-crayon-illustration.png`
- `02a-header-card-title.txt`
- `02b-header-card-artwork.png`
- `03-packaged-sofubi.png`

## Reference assets

The packaged skill keeps a compact set of nine reference images: one pink material reference, one cyan material board, five user-selected dehara references (`01`, `02`, `04`, `10`, `11`), one crayon illustration reference, and one header-card typography/layout reference.

Reference images guide material, construction, or drawing language only. The uploaded portrait remains the sole authority for the person's pose, outfit, accessories, and character-specific content.
