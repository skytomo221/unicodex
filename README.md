# README

## Getting Started

```shell
git clone git@github.com:skytomo221/unicodex.git
cd unicodex
bundle install
bundle exec rails db:create db:migrate db:seed
bundle exec rails tailwindcss:build
bundle exec rails unicode:import_all
bundle exec rails server
```
