<img src=Technotes/Images/icon_1024.png height=128 width=128 style="display: block; margin: auto;">

# NetNewsWire (Fork)

[查看中文文档](README_CN.md)

This is a fork of [Ranchero-Software/NetNewsWire](https://github.com/Ranchero-Software/NetNewsWire) with additional AI-powered features.

NetNewsWire is a free and open-source feed reader for macOS and iOS. It supports [RSS](https://cyber.harvard.edu/rss/rss.html), [Atom](https://datatracker.ietf.org/doc/html/rfc4287), [JSON Feed](https://jsonfeed.org/), and [RSS-in-JSON](https://github.com/scripting/Scripting-News/blob/master/rss-in-json/README.md) formats.

## What's New in This Fork

### AI Translation & Summary (macOS)

This fork adds AI-powered article translation and summarization to NetNewsWire. It uses the OpenAI-compatible API protocol, so it works with any provider that implements this standard.

**Supported providers include (but are not limited to):**

- OpenAI (gpt-4o, gpt-4o-mini, etc.)
- DeepSeek
- Google Gemini (via OpenAI-compatible endpoint)
- Anthropic Claude (via OpenAI-compatible endpoint)
- Any self-hosted service with an OpenAI-compatible API (Ollama, LM Studio, etc.)

**Features:**

- **Article Translation** -- Translate article title and body into your target language. Click the toolbar button again to restore the original text.
- **Article Summary** -- Generate a summary that appears at the top of the article. Supports a dismiss button to close.
- **16 target languages** -- Chinese (Simplified/Traditional), English, Japanese, Korean, French, German, Spanish, Portuguese, Russian, Arabic, Italian, Dutch, Thai, Vietnamese, Indonesian.
- **Custom prompts** -- Optionally configure your own translation and summary prompts for each provider.
- **Multiple providers** -- Add as many providers as you like, and assign different ones for translation and summary.
- **Secure storage** -- API keys are stored in macOS Keychain, never in plain-text config files.
- **Reader View integration** -- When Reader View is active, AI uses the extracted clean content for better results.
- **Task cancellation** -- Switching articles automatically cancels in-progress AI requests to avoid wasting tokens.

## Setup Guide

### AI Configuration

1. Open **NetNewsWire > Settings** (or press `Cmd + ,`).
2. Go to the **AI** tab.

#### Step 1: Add a Provider

Click the **+** button below the AI Providers table to add a new provider. Fill in the following fields:

| Field | Description | Example |
|---|---|---|
| **Name** | A display name for this provider | `My OpenAI` |
| **Endpoint URL** | The API endpoint URL. The app automatically normalizes it (adds `https://` and `/v1/chat/completions` if missing). | `https://api.openai.com` |
| **API Key** | Your API key from the provider | `sk-...` |
| **Model** | The model identifier to use | `gpt-4o-mini` |
| **Translation Prompt** | (Optional) Custom system prompt for translation. Target language is appended automatically. | |
| **Summary Prompt** | (Optional) Custom system prompt for summarization. Target language is appended automatically. | |

#### Step 2: Assign Providers

- **Translation Provider** -- Select which provider to use for translation from the dropdown.
- **Summary Provider** -- Select which provider to use for summarization from the dropdown.
- You can use the same provider for both, or different ones.

#### Step 3: Choose Target Language

Select your preferred target language from the **Target Language** dropdown. Default is `Chinese (Simplified)`.

### Usage

With a provider configured, two new buttons appear in the main window toolbar:

- **Translate** (translate icon) -- Click to translate the current article. Click again to restore the original text.
- **Summarize** (star-badge icon) -- Click to generate a summary displayed at the top of the article.

If no provider is configured for the action, a dialog will prompt you to set one up in Settings.

## Building

You can build and test NetNewsWire without a paid developer account.

```bash
git clone https://github.com/Poco0v0/NetNewsWire.git
cd NetNewsWire

xcodebuild -project NetNewsWire.xcodeproj \
  -scheme NetNewsWire \
  -configuration Debug \
  -destination "platform=macOS,arch=arm64" \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=NO \
  build
```

See [doc/开发环境搭建.md](doc/开发环境搭建.md) for detailed setup instructions.

## Download

Pre-built binaries are available on the [Releases](https://github.com/Poco0v0/NetNewsWire/releases) page.

Since the app is unsigned, macOS will block it on first launch. To open it:

1. Double-click the app -- macOS will block it.
2. Open **System Settings > Privacy & Security**.
3. Click **Open Anyway**.

## Upstream

For information about the original NetNewsWire project, visit [Ranchero-Software/NetNewsWire](https://github.com/Ranchero-Software/NetNewsWire).
