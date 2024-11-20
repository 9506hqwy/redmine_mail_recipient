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

- Issue added

  - `@author`: issue's reporter
  - `@assigned_to`: issue's assignee
  - `@watchers`: issue's watcher
  - `@mentioned`: mentioned user (Redmine5.0 or later)

- Issue updated

  - `@author`: issue's reporter
  - `@assigned_to`: issue's assignee
  - `@previous_assignee`:  issue's previous assignee if assignee is changed
  - `@watchers`: issue's watcher
  - `@commenter`: issue's editor
  - `@commenters`: all issue's editor
  - `@mentioned`: mentioned user (Redmine5.0 or later)

- Document added

  - `@author`: document's creator

- File added

  - `@author`: file's creator

- News added

  - `@author`: news's creator
  - `@watchers`: news's watcher

- Comment added to a news

  - `@author`: news's commenter
  - `@watchers`: news's watcher

- Message added

  - `@author`: message's creator
  - `@watchers`: forum's watcher

- Wiki page added / Wiki page updated

  - `@author`: wiki's creator/editor
  - `@watchers`: wiki's watcher
  - `@mentioned`: mentioned user (Redmine5.0 or later)

## Tested Environment

* Redmine (Docker Image)
  * 3.4
  * 4.1
  * 4.2
  * 5.0
  * 5.1
  * 6.0
* Database
  * SQLite
  * MySQL 5.7 or 8.0
  * PostgreSQL 12
