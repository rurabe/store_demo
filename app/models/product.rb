class Product < ActiveRecord::Base
  attr_accessible :title, :description, :price, :status, :category_ids, :image_path
  has_and_belongs_to_many :categories

  validates :title, presence: :true,
                    uniqueness: { case_sensitive: false }
  validates :description, presence: :true
  validates :status, presence: :true,
                     inclusion: { in: %w(active retired) }
  validates :price, presence: :true,
                    format: { with: /^\d+??(?:\.\d{0,2})?$/ },
                    numericality: { greater_than: 0 }

  scope :by_recency, order('created_at desc')
  scope :active, where(status: 'active')
  scope :for_term, lambda { |term|
      where("lower(title) LIKE ? OR lower(description) LIKE ?", "%#{term.downcase}%", "%#{term.downcase}%")
  }

  def toggle_status
    if status == 'active'
      update_attributes(status: 'retired')
    elsif status == 'retired'
      update_attributes(status: 'active')
    end
  end

  def on_sale?
    percent_of_original.to_i != 1
  end

  def current_price
    sale_price
  end

  def sale_price
    price - discount
  end

  def discount
    price * (1 - percent_of_original)
  end

  def percent_off
    (1 - percent_of_original) * 100
  end

  def percent_of_original
    if category_ids.present? #If it belongs to a category
      percent_of_category = category_sales.inject(1) do |memo,i|
        memo * ( ( 100 - i ) / 100.to_f )
      end
    end
    if category_ids.present?
      percent_of_product * percent_of_category
    else
      percent_of_product
    end
  end

  def product_sales
    Sale.where(group: 'product', status: 'active', foreign_key: self.id).pluck(:percent_off)
  end

  def percent_of_product
    sales_products = product_sales.inject(1) do |memo,i|
      memo * ( ( 100 - i ) / 100.to_f )
    end
  end

  def category_sales
    Sale.where(group: 'category', status: 'active', foreign_key: category_ids).pluck(:percent_off)
  end

  def thumbnail_path
    image_path.sub("stickers", "thumbnails") if image_path
  end

  def product_order_items_count
    OrderItem.find_all_by_product_id(self.id).count
  end
end
