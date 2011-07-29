module Box
  class Item
    attr_accessor :data, :api, :parent
    attr_accessor :cached_info

    def initialize(api, parent, info)
      @api = api
      @parent = parent
      @data = Hash.new

      update_info(info) # merges with the info hash, and renames some fields
    end

    def self.type; raise "Overwrite this method"; end
    def self.types; type + 's'; end

    # should be a better way of doing this
    def type; self.class.type; end
    def types; self.class.types; end

    def id; @data['id']; end # overwrite Object#id, which is not what we want

    # use cached info or update it if requested
    def info(refresh = false)
      return self if @cached_info and not refresh

      @cached_info = true
      update_info(get_info)

      self
    end
    # move the item to the destination folder
    def move(destination)
      @api.move(type, id, destination.id)

      parent.delete_info(self.types)
      destination.delete_info(self.types)

      @parent = destination

      self
    end

    # copy the file (folder not supported in the api) to the destination folder
    def copy(destination)
      @api.copy(type, id, destination.id)

      destination.delete_info(self.types)

      self.class.new(api, destination, @data)
    end

    # rename the item
    def rename(new_name)
      @api.rename(type, id, new_name)

      update_info('name' => new_name)

      self
    end

    # delete the item
    def delete
      @api.delete(type, id)

      parent.delete_info(self.types)
      @parent = nil

      self
    end

    def description(message)
      @api.set_description(type, id, message)

      self
    end

    # get the path, starting with /
    def path
      "#{ parent.path + '/' if parent }#{ name }"
    end

    # use method_missing as to provide an easy way to access the item's properties
    def method_missing(sym, *args, &block)
      str = sym.to_s

      # return the value if it already exists
      return @data[str] if @data.key?(str)

      # value didn't exist, so update the info
      self.info

      # try again
      return @data[str] if @data.key?(str)

      # we didn't find a value, so it must be invalid
      super
    end

    protected

    # sub-classes are meant to implement this
    def get_info(*args); Hash.new; end

    def update_info(info)
      ninfo = Hash.new

      # the api is stupid and some fields are named 'file_id' or 'id' inconsistently, so trim the type off
      info.each do |name, value|
        if name.to_s =~ /^#{ type }_(.+)$/; ninfo[$1] = value
        else; ninfo[name.to_s] = value; end
      end

      @data.merge!(ninfo) # merge in the updated info
    end

    def delete_info(field)
      @cached_info = false
      @data.delete(field)
    end

    def clear_info
      @cached_info = false
      @data.clear
    end
  end
end
