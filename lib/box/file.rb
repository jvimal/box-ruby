require 'box/item'

module Box
  # Represents a file stored on Box. Any attributes or actions typical to
  # a Box file can be accessed through this class.

  class File < Item
    # (see Item.type)
    def self.type; 'file'; end

    # Download this file to the specified path.
    #
    # @param [String] path The path to write the file.
    def download(path)
      @api.download(path, id)
    end

    # Overwrite this file, using the file at the specified path
    #
    # @param [String] path The path to the file to upload.
    # @return [File] self
    def upload_overwrite(path)
      info = @api.overwrite(path, id)['files']['file']

      clear_info
      update_info(info)

      self
    end

    # Upload a new copy of this file. The name will be "file (#).ext"
    # for the each additional copy.
    #
    # @param path (see #upload_overwrite)
    # @return [File] The newly created file.
    def upload_copy(path)
      info = @api.new_copy(path, id)['files']['file']
      parent.delete_info('files')

      self.class.new(api, parent, info)
    end

    protected

    # (see Item#get_info)
    def get_info
      @api.get_file_info(id)['info']
    end
  end
end
