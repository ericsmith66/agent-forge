class CreateArtifacts < ActiveRecord::Migration[8.0]
  def change
    create_table :artifacts do |t|
      t.references :project, null: false, foreign_key: true
      t.bigint :parent_id
      t.string :artifact_type, null: false
      t.string :title, null: false
      t.jsonb :jsonb_document, null: false, default: {}
      t.string :status, null: false, default: "draft"
      t.integer :position

      t.timestamps
    end

    add_index :artifacts, :parent_id
    add_index :artifacts, :artifact_type
    add_index :artifacts, :status
    add_foreign_key :artifacts, :artifacts, column: :parent_id
  end
end
