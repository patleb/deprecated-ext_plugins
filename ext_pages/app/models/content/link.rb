class Content::Link < Content
  translates :link
  translates :name

  belongs_to :page
end
