class User < ActiveRecord::Base
  attr_accessible :name, :email, :password, :password_confirmation, :guest, :rank, :wins, :loses, :open_for_play, :avatar, :salt, :role, :last_request_at, :email_confirmed, :notify_pendding_move, :connected, :level
  attr_accessor :password
  
  before_save :make_password
  
  has_many :current_games, :class_name => "Game", :foreign_key => "current_player_id", :conditions => "status != 1 and mode != 0", :order => "updated_at DESC", :limit => 4
  has_many :comments, :dependent => :destroy
  has_attached_file :avatar, :styles => { :small => "24x24>", :medium => "48x48>" }
  has_many :authentications, :dependent => :destroy
  has_many :pro_games, :class_name => 'Game', :foreign_key => "uploader"
  has_many :relationships, :foreign_key => "follower_id", :dependent => :destroy
  has_many :following, :through => :relationships, :source => :followed
  has_many :reverse_relationships, :foreign_key => "followed_id", 
                                   :class_name => "Relationship",
                                   :dependent => :destroy
  has_many :followers, :through => :reverse_relationships, :source => :follower
  
  validates_presence_of :name
  validates_length_of :name, :within => 2..9, :message => I18n.t(:name_length_msg)
  validates_presence_of :email
  validates_uniqueness_of :name, :email, :allow_blank => true, :case_sensitive => false, :message => I18n.t(:unique_msg)
  validates_format_of :email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i, :allow_blank => true, :message => I18n.t(:invalid_email_msg)
  validates_presence_of :password, :on => :create
  validates_confirmation_of :password
  validates_length_of :password, :within => 6..20, :allow_blank => true, :message => I18n.t(:password_length_msg)
  validates_attachment_size :avatar, :less_than => 128.kilobytes
  validates_attachment_content_type :avatar, :content_type => ['image/jpeg', 'image/png']
  
  scope :on_play_list, lambda { |user_id| where("id != #{user_id} and open_for_play = true").order("last_request_at DESC") }
  
  def self.authenticate(login, pass)
    @user = find(:first, :conditions => ["lower(name) = ?", login.downcase]) || find(:first, :conditions => ["lower(email) = ?", login.downcase])
    return @user if @user && @user.has_password?(pass)
  end
  
  def self.authenticate_with_salt(user_id, user_salt)
    user = User.find_by_id(user_id)
    user && user.salt == user_salt ? user : nil
  end
  
  def has_password?(pass)
    self.encrypted_password == encrypt_password(pass)
  end
  
  def following?(followed)
    if relationships.find_by_followed_id(followed)
      return true
    else
      return false
    end
  end
  
  def follow!(followed)
    relationships.create!(:followed_id => followed.id)
  end
  
  def unfollow!(followed)
    relationships.find_by_followed_id(followed).destroy
  end
  
  def feed
    Game.from_users_followed_by(self)
  end
  
  def win_rate
    r = sprintf("%.2f", wins.to_f/(wins+loses))
    r.to_f
  end
  
  def online?
    connected > 0
  end
  
  def admin?
    role.to_i == 2
  end
  
  def robot?
    gnugo? || fuego?
  end
  
  def gnugo?
    role.to_i == 98
  end
  
  def fuego?
    role.to_i == 99
  end
  
  private
    def make_password
      unless password.blank?
        self.salt = BCrypt::Engine.generate_salt
        self.encrypted_password = encrypt_password(password)
      end
    end
  
    def encrypt_password(pass)
      BCrypt::Engine.hash_secret(pass, salt)
    end
end


# == Schema Information
#
# Table name: users
#
#  id                   :integer         not null, primary key
#  name                 :string(255)
#  email                :string(255)
#  encrypted_password   :string(255)
#  salt                 :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#  wins                 :integer         default(0)
#  loses                :integer         default(0)
#  points               :integer         default(0)
#  open_for_play        :boolean         default(TRUE)
#  avatar_file_name     :string(255)
#  avatar_content_type  :string(255)
#  avatar_file_size     :integer
#  avatar_updated_at    :datetime
#  last_request_at      :datetime
#  role                 :integer         default(0)
#  email_confirmed      :boolean         default(FALSE)
#  notify_pendding_move :boolean         default(FALSE)
#  connected            :integer         default(0)
#  level                :integer         default(0)
#

