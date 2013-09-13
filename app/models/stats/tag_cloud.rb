class TagCloud
    # tag cloud code inspired by this article
    #  http://www.juixe.com/techknow/index.php/2006/07/15/acts-as-taggable-tag-cloud/
    #
    # TODO: parameterize limit

  attr_reader :user, :cut_off, :divisor

  def initialize(user, cut_off = nil)
    @user     = user
    @cut_off  = cut_off
  end

  def tags
    unless @tags
      params = [ sql(@cut_off), user.id ]
      params += [ @cut_off, @cut_off ] if @cut_off
      @tags = Tag.find_by_sql(params).sort_by { |tag| tag.name.downcase }
    end

    @tags
  end

  def relative_size(tag)
    (tag.count.to_i - min) / divisor
  end

private

  def sql(cut_off = nil)
    raw_sql = <<-SQL
      SELECT tags.id, tags.name AS name, count(*) AS count
        FROM taggings, tags, todos
        WHERE tags.id = tag_id
        AND taggings.taggable_id=todos.id
        AND todos.user_id=?
        AND taggings.taggable_type='Todo'

        #{timebox_todos(cut_off)}

        GROUP BY tags.id, tags.name
        ORDER BY count DESC, name
        LIMIT 100
     SQL

     raw_sql.squish
  end

  def timebox_todos(cut_off)
    cut_off ? 'AND (todos.created_at > ? OR todos.completed_at > ?)' : ''
  end

  def tag_counts
    @tag_counts ||= tags.map { |t| t.count.to_i }
  end

  def divisor
    @divisor ||= ((max - min) / levels) + 1
  end

  def min
    0
  end

  def max
    tag_counts.max
  end

  def levels
    10
  end
end
