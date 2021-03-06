class Position < ActiveRecord::Base
  belongs_to :handicap
  belongs_to :strategy
  has_many :appearances
  has_many :games, through: :appearances
  has_many :prev_moves, class_name: 'Move', foreign_key: 'next_position_id'
  has_many :next_moves, class_name: 'Move', foreign_key: 'prev_position_id'
  has_many :prev_positions, :through => :prev_moves, :source => :prev_position
  has_many :next_positions, :through => :next_moves, :source => :next_position
  has_many :backward_references, class_name: 'PosReference', foreign_key: 'referred_id'
  has_many :forward_references, class_name: 'PosReference', foreign_key: 'referrer_id'
  has_many :referrers, :through => :backward_references, :source => :referrer
  has_many :referred_positions, :through => :forward_references, :source => :referred
  belongs_to :latest_post, class_name: 'Wikipost', foreign_key: 'latest_post_id'
  has_many :wikiposts, foreign_key: 'position_id'
  has_many :discussions, foreign_key: 'position_id'
  has_many :watches
  has_many :watchers, :through => :watches, :source => :user
  has_many :notes
  has_many :note_references
  has_many :referrer_notes, :through => :note_references, :source => :note

  def self.find_or_create(sfen)
    board = Board.new
    return nil unless (board.set_from_sfen(sfen) == :normal)
    unless (position = Position.find_by(sfen: board.to_sfen))
      position = Position.create(:sfen => board.to_sfen, :handicap_id => board.handicap_id)
    end
    return position
  end

  def self.reduce_views_count
    positions = Position.where('views >= 2').order(views: :desc)
    ActiveRecord::Base.transaction do
      positions.each_with_index {|p,i|
        divider = 2
        if i < 30
          num = p.appearances.first.num
          if num == 0
            divider = 16
          elsif num == 1
            divider = 8
          elsif num == 2
            divider = 4
          elsif num == 3
            divider = 3
          end
        end
        puts p.views.to_s + "/" + divider.to_s
        p.update_attributes(views: p.views / divider)
      }
    end
    ""
  end

  def update_stat(category, result)
    return unless [0, 1, 2, 3].include?(category)
    if (result == 0) 
      self["stat" + category.to_s + "_black"] += 1
    elsif (result == 1)
      self["stat" + category.to_s + "_white"] += 1
    elsif (result == 2)
      self["stat" + category.to_s + "_draw"] += 1
    end
    save
  end
  
  def update_strategy(new_strategy, hard = false)
    if (hard)
      update_attributes(:strategy_id => new_strategy.id) unless (new_strategy.id == self.strategy_id || new_strategy.descendant_ids.include?(self.strategy_id))
    else
      return self.strategy if (!new_strategy)
      update_attributes(:strategy_id => new_strategy.id) if (!self.strategy_id || self.strategy.descendant_ids.include?(new_strategy.id))
    end
  	return self.strategy
  end

  def overwrite_strategy(new_strategy)
    update_attributes(:strategy_id => new_strategy.id)
  end

  def update_strategy_category4moves(new_strategy, hard = false)
    joseki_moves = self.next_moves.where('stat1_total = 0 and stat2_total = 0 and stat3_total = 0')
    joseki_moves.each do |move|
      move.next_position.update_strategy(new_strategy, hard)
      move.next_position.update_strategy_category4moves(new_strategy, hard)
    end
  end
  
  def to_board
    board = Board.new
    board.set_from_sfen(self.sfen)
    return board
  end  

  def win_stat(category)
    return "　　-　　" if self["stat" + category.to_s + "_black"] == 0 && self["stat" + category.to_s + "_white"] == 0
    "▲" + self["stat" + category.to_s + "_black"].to_s + "勝 - △" + self["stat" + category.to_s + "_white"].to_s + "勝"
  end

end
