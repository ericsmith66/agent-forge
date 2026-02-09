class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name
      t.string :status, null: false, default: "pending"
      t.string :aider_desk_task_id
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :tasks, :aider_desk_task_id
  end
end
