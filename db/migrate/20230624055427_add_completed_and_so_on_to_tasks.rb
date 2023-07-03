class AddCompletedAndSoOnToTasks < ActiveRecord::Migration[6.1]
  def change
    add_column :tasks, :completed, :boolean
    add_column :tasks, :due_date, :date
  end
end
