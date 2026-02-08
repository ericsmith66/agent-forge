# Baseline Gemfile — agent-forge

**Date:** 2026-02-08  
**Stack:** Ruby 3.3+ / Rails 8.1+ / Solid stack / Minitest

---

This is the baseline Gemfile for bootstrapping agent-forge. It matches the nextgen-plaid patterns (Rails 8, Solid stack, Devise/Pundit, Minitest, Tailwind/ViewComponent) and adds the gems required for Epic 001 (AiderDesk integration).

```ruby
# Gemfile – agent-forge (Ruby 3.3+ / Rails 8.1+ baseline – February 2026)
source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.10"  # Match nextgen-plaid for consistency

gem "rails", "~> 8.1.1"

# Solid stack – modern Rails defaults (no Redis)
gem "solid_queue"      # background jobs
gem "solid_cache"      # caching
gem "solid_cable"      # ActionCable backend

# Hotwire / frontend foundation
gem "turbo-rails"
gem "stimulus-rails"
gem "importmap-rails"  # no JS bundler needed
gem "tailwindcss-rails" # Tailwind CSS
gem "view_component"   # modular Ruby views

# Auth & security
gem "devise"           # authentication
gem "pundit"           # authorization

# Core utilities
gem "propshaft"        # asset pipeline (Rails 8 default)
gem "puma", ">= 6.0"   # web server
gem "tzinfo-data", platforms: %i[ windows jruby ]

# AI / Agent framework – critical for multi-agent orchestration
gem "ai-agents", "~> 0.7.0"  # or latest stable (check rubygems.org)

# HTTP client for AiderDesk REST API
gem "httparty"

# Markdown rendering (for chat, artifacts, docs)
gem "commonmarker"

# Development & test
group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "pry-rails"
  gem "minitest", "~> 5.0"
  gem "minitest-mock"
end

group :development do
  gem "web-console"
  gem "bullet"  # N+1 query detection
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "vcr"               # record HTTP for AiderDesk API tests
  gem "webmock"           # stub HTTP for reliability
  gem "simplecov", require: false  # code coverage (≥ 90% target)
end

# Optional – add later as needed
# gem "chartkick"        # dashboards
# gem "sanitize"         # HTML sanitization
# gem "kaminari"         # pagination
```

---

### Quick Setup Steps (After Pasting Gemfile)

```bash
# Install dependencies
bundle install

# Create Rails app structure if not already done
rails new . --force --database=postgresql --css tailwind --skip-jbuilder

# Generate initial files (optional but recommended)
bin/rails generate devise:install
bin/rails generate pundit:install

# Set up Solid Queue
bin/rails solid_queue:install

# Do NOT commit without explicit approval
```

---

### Why This Baseline

- Matches **nextgen-plaid** closely (Rails 8.1, Solid stack, Devise/Pundit, Minitest, Tailwind/ViewComponent).
- Includes **ai-agents** gem for multi-agent orchestration (handoffs, tool calling).
- Adds **httparty** for AiderDesk REST calls (port 24337).
- Adds **vcr** + **webmock** + **simplecov** for Epic 001 testing requirements.
- Keeps it lean — no unnecessary bloat (add chartkick, sanitize, etc. later).
