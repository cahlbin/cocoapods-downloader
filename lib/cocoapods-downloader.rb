module Pod
  module Downloader
    require 'cocoapods-downloader/gem_version'
    require 'cocoapods-downloader/api'
    require 'cocoapods-downloader/api_exposable'
    require 'cocoapods-downloader/base'


    # @return [Hash{Symbol=>Class}] The symbol of the options array associated
    #         with each class.
    #
    def self.downloader_class_by_key
      require 'cocoapods-downloader/git'
      require 'cocoapods-downloader/mercurial'
      require 'cocoapods-downloader/subversion'
      require 'cocoapods-downloader/http'
      require 'cocoapods-downloader/bazaar'

      {
        :git  => Git,
        :hg   => Mercurial,
        :svn  => Subversion,
        :http => Http,
        :bzr  => Bazaar,
      }
    end

    # @return [Downloader::Base] A concrete downloader according to the
    #         options.
    #
    # @todo   Improve the common support for the cache in Base and add specs.
    # @todo   Find a way to switch to GitHub tarballs if no cache is used. Have
    #         global options for the Downloader cache?
    #
    def self.for_target(target_path, options)

      if target_path.nil?
        raise DownloaderError, "No target path provided."
      end

      if options.nil? || options.empty?
        raise DownloaderError, "No source url provided."
      end

      options = options.dup
      klass = nil
      url = nil
      downloader_class_by_key.each do |key, key_klass|
        url = options.delete(key)
        if url
          klass = key_klass
          break
        end
      end

      unless klass
        raise DownloaderError, "Unsupported download strategy `#{options.inspect}`."
      end

      if klass == Git && url.to_s =~ /github.com/
        klass = GitHub
      end

      klass.new(target_path, url, options)
    end

    # Denotes the error generated by a Downloader
    #
    class DownloaderError < StandardError; end

  end
end
