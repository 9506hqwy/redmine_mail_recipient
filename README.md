# Redmine Mail Recipient

This plugin provides a mail recipient customization method per project.

## Features

- Deliver mail to `TO` recipient by using keyword.
- Deliver mail to `CC` recipient by using keyword.

## Installation

1. Download plugin in Redmine plugin directory.
   ```sh
   git clone https://github.com/9506hqwy/redmine_mail_recipient.git
   ```
2. Install plugin in Redmine directory.
   ```sh
   bundle exec rake redmine:plugins:migrate NAME=redmine_mail_recipient RAILS_ENV=production
   ```
3. Start Redmine

## Configuration

1. Enable plugin module.

   Check [Mail Recipient] in project setting.

2. Set in [Mail Recipient] tab in project setting.

   - [Email notifications]

     Select notification event.

   - [Tracker]

     Select tracker.

   - [TO]

     Input `TO` recipient keyword.
     If input multi keyword, keyword is separated by comma(,).

   - [CC]

     Input `CC` recipient keyword.
     If input multi keyword, keyword is separated by comma(,).

Recipient keyword is bellow.

- Create issue

  - `@assigned_to`: issue's assignee
  - `@watchers`: issue's watcher
  - `@mentioned`: mentioned user (Redmine5.0 or later)

- Update issue

  - `@author`: issue's reporter
  - `@assigned_to`: issue's assignee
  - `@previous_assignee`:  issue's previous assignee if assignee is changed
  - `@watchers`: issue's watcher
  - `@commenter`: issue's editor
  - `@commenters`: all issue's editor
  - `@mentioned`: mentioned user (Redmine5.0 or later)

- Create news

  - `@watchers`: news's watcher

- Comment news

  - `@watchers`: news's watcher

- Create message

  - `@watchers`: forum's watcher

- Create/Update wiki

  - `@watchers`: wiki's watcher
  - `@mentioned`: mentioned user (Redmine5.0 or later)

## Tested Environment

* Redmine (Docker Image)
  * 3.4
  * 4.1
  * 4.2
  * 5.0
* Database
  * SQLite
  * MySQL 5.7
  * PostgreSQL 12
