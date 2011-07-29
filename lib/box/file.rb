require 'box/item'

module Box
  class File < Item
    def self.type; 'file'; end

    # download the file to the specified path
    def download(path)
      @api.download(path, id)
    end

    # overwrite this file, using the file at the specified path
    def upload_overwrite(path)
      info = @api.overwrite(path, id)['files']['file']

      clear_info
      update_info(info)

      self
    end

    # upload a new copy of this file, the name being 'file (#).ext' for the #th copy
    def upload_copy(path)
      info = @api.new_copy(path, id)['files']['file']
      parent.delete_info('files')

      self.class.new(api, parent, info)
    end

    protected

    # get the file info
    def get_info
      @api.get_file_info(id)['info']
    end
  end
end
