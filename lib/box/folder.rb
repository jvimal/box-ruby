require 'box/item'
require 'box/file'

module Box
  class Folder < Item
    attr_accessor :cached_tree

    def self.type; 'folder'; end

    # override the existing info method so that we create empty folders/files first
    def info(refresh = false)
      return self if @cached_info and not refresh

      create_sub_items(nil, Box::Folder)
      create_sub_items(nil, Box::File)

      super
    end

    # use the cached tree or update it if requested
    def tree(refresh = false)
      return self if @cached_tree and not refresh

      @cached_info = true # count the info as cached as well
      @cached_tree = true

      update_info(get_tree)
      force_cached_tree

      self
    end

    # create a new folder using this folder as the parent
    def create(name, share = 0)
      info = @api.create_folder(id, name, share)['folder']

      delete_info('folders')

      Box::Folder.new(api, self, info)
    end

    # upload a new file using this folder as the parent
    def upload(path)
      info = @api.upload(path, id)['files']['file']

      delete_info('files')

      Box::File.new(api, self, info)
    end

    # search for items using criteria
    def find(criteria)
      recursive = criteria.delete(:recursive)
      recursive = false if recursive == nil # default to false for performance reasons

      tree if recursive # get the full tree

      find!(criteria, recursive)
    end

    protected

    # get the folder info
    def get_info
      @api.get_account_tree(id, 'onelevel')['tree']['folder']
    end

    # get the folder info and all nested items
    def get_tree
      @api.get_account_tree(id)['tree']['folder']
    end

    def clear_info
      @cached_tree = false
      super
    end

    # overload Item#update_info to create the subobjects like Files and Folders
    def update_info(info)
      if folders = info.delete('folders')
        create_sub_items(folders, Box::Folder)
      end

      if files = info.delete('files')
        create_sub_items(files, Box::File)
      end

      super
    end

    # create the sub items, so they are objects rather than hashes
    def create_sub_items(items, item_class)
      @data[item_class.types] ||= Array.new

      return unless items

      temp = items[item_class.type]
      temp = [ temp ] if temp.class == Hash # lone folders need to be packaged into an array

      temp.collect do |item_info|
        item_class.new(api, self, item_info).tap do |item|
          @data[item_class.types] << item
        end
      end
    end

    # update the cached status of all sub items, as we got the entire tree
    def force_cached_tree
      create_sub_items(nil, Box::Folder)
      create_sub_items(nil, Box::File)

      files.each do |file|
        file.cached_info = true
      end

      folders.each do |folder|
        folder.cached_info = true
        folder.cached_tree = true

        folder.force_cached_tree
      end
    end

    # search for any files/folders that match the criteria sent
    def find!(criteria, recursive)
      matches = (files + folders).collect do |item| # search over our files and folders
        match = criteria.all? do |key, value| # make sure all criteria pass
          item.send(key) == value.to_s rescue false
        end

        item if match # use the item if it is a match
      end

      if recursive
        folders.each do |folder| # recursive step
          matches += folder.find!(criteria, recursive) # search each folder
        end
      end

      matches.compact # return the results without nils
    end
  end
end
