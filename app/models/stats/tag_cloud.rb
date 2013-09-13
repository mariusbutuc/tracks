class TagCloud
  attr_reader :current_user, :cut_off_3months,
              :tags_for_cloud, :tags_min, :tags_divisor,
              :tags_for_cloud_90days, :tags_min_90days, :tags_divisor_90days
  def initialize(current_user, cut_off_3months)
    @current_user     = current_user
    @cut_off_3months  = cut_off_3months
  end

  def compute
    # tag cloud code inspired by this article
    #  http://www.juixe.com/techknow/index.php/2006/07/15/acts-as-taggable-tag-cloud/

    levels=10
    # TODO: parameterize limit

    # Get the tag cloud for all tags for actions
    params = [
      sql,
      current_user.id
    ]
    @tags_for_cloud = Tag.find_by_sql(params).sort_by { |tag|
      tag.name.downcase
    }

    max, @tags_min = 0, 0
    @tags_for_cloud.each { |t|
      max = [t.count.to_i, max].max
      @tags_min = [t.count.to_i, @tags_min].min
    }

    @tags_divisor = ((max - @tags_min) / levels) + 1

    # Get the tag cloud for all tags for actions
    params = [
      sql(@cut_off_3months),
      current_user.id,
      @cut_off_3months,
      @cut_off_3months
    ]
    @tags_for_cloud_90days = Tag.find_by_sql(params).sort_by { |tag|
      tag.name.downcase
    }

    max_90days, @tags_min_90days = 0, 0
    @tags_for_cloud_90days.each { |t|
      max_90days = [t.count.to_i, max_90days].max
      @tags_min_90days = [t.count.to_i, @tags_min_90days].min
    }

    @tags_divisor_90days = ((max_90days - @tags_min_90days) / levels) + 1
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
