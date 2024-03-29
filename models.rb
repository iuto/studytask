require 'bundler/setup'
Bundler.require

ActiveRecord::Base.establish_connection

class User < ActiveRecord::Base
    has_secure_password
    validates :name,
        presence: true,
        format: { with: /\A\w+\z/ }
    validates :password,
        length: { in:5..10 }
    has_many :tasks
end

class List < ActiveRecord::Base
    has_many :tasks
end

class Task < ActiveRecord::Base
    validates :title,
        presence: true
    belongs_to :user
    belongs_to :list
    
    scope :due_over, -> { where('due_date < ?', Date.today).where(completed: [nil, false]) }
    scope :had_by, -> (user) { where(user_id: user.id) }
    
    def remained_days
        return (due_date - Date.today).to_i
    end

    # 日付別表示のために追加
    def due_today?
        due_date == Date.today
    end

    def due_tomorrow?
        due_date == Date.today + 1
    end

    # ハイライトのために追加
    def due_on?(wday)
        due_date.wday == wday
    end
end
