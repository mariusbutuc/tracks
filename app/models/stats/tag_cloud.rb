class TagCloud
    # tag cloud code inspired by this article
    #  http://www.juixe.com/techknow/index.php/2006/07/15/acts-as-taggable-tag-cloud/
    #
    # TODO: parameterize limit

  attr_reader :user, :cut_off,
              :tags, :min, :divisor,
              :tags_90days, :min_90days, :divisor_90days
  def initialize(user, cut_off)
    @user             = user
    @cut_off  = cut_off
  end

  def compute

    levels = 10
    params = [
      sql, user.id
    ]
    @tags = Tag.find_by_sql(params).sort_by { |tag|
      tag.name.downcase
    }

    max, @min = 0, 0
    @tags.each { |t|
      max = [t.count.to_i, max].max
      @min = [t.count.to_i, @min].min
    }

    @divisor = ((max - @min) / levels) + 1

    params = [
      sql(@cut_off), user.id, @cut_off, @cut_off
    ]
    @tags_90days = Tag.find_by_sql(params).sort_by { |tag|
      tag.name.downcase
    }

    max_90days, @min_90days = 0, 0
    @tags_90days.each { |t|
      max_90days = [t.count.to_i, max_90days].max
      @min_90days = [t.count.to_i, @min_90days].min
    }

    @divisor_90days = ((max_90days - @min_90days) / levels) + 1
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
end
