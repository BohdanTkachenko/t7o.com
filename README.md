# t7o.com

Source for [t7o.com](https://t7o.com) — my personal blog about personal projects and open-source work.

Built with [Zola](https://www.getzola.org/).

## Development

Requires [Nix](https://nixos.org/) with flakes and [direnv](https://direnv.net/). On first entry, run:

```sh
direnv allow
```

The devShell provides `zola` on `PATH`.

```sh
zola serve   # local preview with live reload
zola build   # render to public/
zola check   # validate links and content
```

See [AGENTS.md](AGENTS.md) for guidance given to AI coding assistants.

## License

- Code: [MIT](LICENSE-CODE)
- Content (posts, images, etc.): [CC BY 4.0](LICENSE-CONTENT)
