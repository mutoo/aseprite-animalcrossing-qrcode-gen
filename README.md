# Animal Crossing QRCode Generator for Aseprite

This is a custom script for generate Animal Crossing QRCode in [Aseprite](http://www.aseprite.org/).

## Install

1. Download the repo as Zip file.
2. Open Aseprite, Select `File > Scripts > Open Scripts Folder`.
3. Extract the zip in the Scripts folder, and rename it to `animalcrossing`.
4. Restart Aseprite.

P.S. the `lib` folder is a necessary part of this script, so please leave it with `generate-qrcode.lua`.

## Usage

1. Setup a Sprite with `32px` width and height.
2. Change Color Mode to `Indexed`.
3. Setup a palette with no more than 16 colors (including transparent).
4. Enjoy drawing.
5. Export QRCode by clicking `File > Scripts > animalcrossing > generate-qrcode`.
6. Edit the Title/Author/Town in the dialog.
7. Click `Generate` button to create a new sprite with QRCode.
8. Scan the QRCode with Nintendo Switch mobile app.

![screenshot-1](./screenshot/qrcode-1.png)
![screenshot-2](./screenshot/qrcode-2.png)

### User Preference

Aseprite doesn't support user preference at the moment this script had been made. 

But you could create or edit the `settings.lua` in the script folder to pre-fill your detail, so that you don't need to refill these setting every time you want to generate the QRCode. 

```lua
-- settings.lua
return {
    title = 'Untitled',
    author = 'Mutoo',
    town = 'Aseprite',
}
```

## Limitation

Currently, the generator only support the basic 32 x 32 custom design. More design type would be available in future development.

The palette is limit to 16 colors with transparent, and when being exported to qrcode, it would be converted to the closest colors in the internal palette (check `lib/palettes.lua` for reference).

The design will not be editable on both Animal Crossing New Leaf or Animal Crossing New Horizons due to the lack of user identification in the data.

## License

MIT

## Credits

Thanks [Thulinma](https://github.com/Thulinma/) for creating the [ACNLPatternTool Web App](https://acpatterns.com/).
The ACNL data layout and palettes are extracted from that repo and ported to Lua language.

Thanks Patrick Gundlach for create the [luaqrcode](http://speedata.github.io/luaqrcode/docs/qrencode.html).
