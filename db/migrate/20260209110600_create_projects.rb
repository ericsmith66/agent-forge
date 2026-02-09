class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.text :description
      t.string :project_dir, null: false
      t.jsonb :settings, null: false, default: {}
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :projects, :name, unique: true
    add_index :projects, :active
  end
end
