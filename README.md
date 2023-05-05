# llm-cli

Need to Google that command you can't quite remember? Use a Large Language Model instead!

* Leverages a LLM to generate the command line instruction you want to execute
* Just describe what you want to do and the LLM will generate the commands for you.
* You can be vague, you will be prompted for parameter details (file and folder names, branches, commit messages etc)

<img width="623" alt="example" src="https://user-images.githubusercontent.com/368013/232639264-cd136de1-a1cd-4e32-ba39-ee860793d9de.png">

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
export OPENAI_API_KEY=sk-123456

# optionally you can specify your preferred model
export LLM_MODEL=gpt-3.5-turbo
```

## Usage

Pass the description to the `llm` executable

```shell
llm the description of the command you want to run
# .. 
llm I want to do this then do this. Then do this
```

Execute a query and have the response returned on the command line

```shell
llm -q are there any warm blooded reptiles?
```

you can specify your model preference using `-m gpt-3.5-turbo` (as will default to `gpt-4` if you have API access to it)

If you would like to verbose details use the `-v` flag

## Contributing

1. Fork it (<https://github.com/stakach/llm-cli/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Stephen von Takach](https://github.com/stakach) - creator and maintainer
