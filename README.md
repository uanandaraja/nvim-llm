# nvim-llm

AI-Powered Chat and Code Assistance for Neovim

## ✨ Features

- Use your preferred models. We use Open Router API so you can choose whatever model you like.
- Add buffer(s) to the LLM context
- Add url(s) to the LLM context
- Add errors in the buffer(s) to the LLM context
- Configure your own prompt

## 📦 Requirements

- Neovim 0.7+
- OpenRouter API Key
- Dependencies:
  - `plenary.nvim`
  - `nvim-notify`
  - `nui.nvim`

## 🚀 Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    'uanandaraja/nvim-llm.nvim',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'rcarriga/nvim-notify',
        'MunifTanjim/nui.nvim'
    },
    config = true
}
```

## 🔧 Configuration

### Basic Setup

```lua
require('nvim-llm').setup({
    -- Optional custom configuration
    default_model = "anthropic/claude-3.5-sonnet",
    system_prompt = "You are a helpful coding assistant."
})
```

## 🎮 Keybindings

- `<leader>lo`: Open LLM Chat
- `<leader>ls`: Submit prompt
- `<leader>lc`: Clear chat
- `<leader>lq`: Quit chat
- `<leader>lf`: Add file reference
- `<leader>lb`: Add current buffer
- `<leader>lm`: Select Model
- `<leader>lu`: Add URL reference
- `<leader>lp`: Configure system prompt

## 💡 Usage

1. First time: You'll be prompted for an OpenRouter API key
2. Open chat with `:LLM` or `<leader>lo`
3. Type your prompt
4. Use keybindings to add context (files, URLs, errors)
5. Submit with `<leader>ls`

## 🔑 API Key

- Obtained from [OpenRouter](https://openrouter.ai/)
- Securely stored in Neovim data directory
- Can be updated anytime

## 📄 License

Apache License

## TODO in the future

- Document the config better so people could do whatever they want
