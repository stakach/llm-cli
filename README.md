# llm-cli

Need to Google that command you can't quite remember? Use a Large Language Model instead!

* Leverages a LLM to generate the command line instruction you want to execute
* Just describe what you want to do and the LLM will generate the commands for you.
* You can be vague, you will be prompted for parameter details (file and folder names, branches, commit messages etc)

<img width="621" alt="example" src="https://user-images.githubusercontent.com/368013/232493882-6bb8b4f8-6988-41f1-9f25-a1685e0c1750.png">

## Installation

Make sure you have [crystal lang](https://crystal-lang.org/install/) installed to build the project

```shell
git clone https://github.com/stakach/llm-cli.git
cd llm-cli
shards build
cp ./bin/llm /bin/llm
```

You'll then need to configure a LLM, currently only OpenAPI is implemented. You can add it to your dotfiles.

```shell
vi ~/.bashrc
# then add your OpenAPI Key
# export OPENAI_API_KEY=sk-123456
```

## Usage

Pass the description to the `llm` executable

```shell
llm the description of the command you want to run
# .. 
llm I want to do this then do this. Then do this
```

## Contributing

1. Fork it (<https://github.com/stakach/llm-cli/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Stephen von Takach](https://github.com/stakach) - creator and maintainer
