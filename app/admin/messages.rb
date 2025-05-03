ActiveAdmin.register Message do
  # remove_filter :chat, :user # Keep removed or add explicit filters below

  filter :id
  filter :content
  filter :user
  filter :chat
  filter :created_at

  index do
    selectable_column
    id_column
    column :user
    column :chat
    column("Content Preview") { |msg| truncate(msg.content, length: 50) }
    column :total_tokens
    column :total_costs
    column :created_at
    actions
  end

  menu parent: "Chats"
end
