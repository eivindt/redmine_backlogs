class ChangeColumnHistoryOnHistory < ActiveRecord::Migration[5.2]
  # MySQL's text type is limited to 64 KB, which large issue histories exceed.
  # PostgreSQL and SQLite text columns are unbounded, so nothing to do there.
  def self.up
    change_column :rb_issue_history, :history, :mediumtext if Redmine::Database.mysql?
  end

  def self.down
    change_column :rb_issue_history, :history, :text if Redmine::Database.mysql?
  end
end
