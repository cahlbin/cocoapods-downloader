require File.expand_path('../spec_helper', __FILE__)

module Pod
  module Downloader
    describe 'HTTP' do

      before do
        tmp_folder.rmtree if tmp_folder.exist?
      end

      it 'download file and unzip it' do
        options = { :http => 'http://dl.google.com/googleadmobadssdk/googleadmobsearchadssdkios.zip' }
        downloader = Downloader.for_target(tmp_folder, options)
        VCR.use_cassette('tarballs', :record => :new_episodes) { downloader.download }
        tmp_folder('GoogleAdMobSearchAdsSDK/GADSearchRequest.h').should.exist
        tmp_folder('GoogleAdMobSearchAdsSDK/GADSearchRequest.h').read.strip.should =~ /Google Search Ads iOS SDK/
      end

      it 'should download file and unzip it when the target folder name contains quotes or spaces' do
        options = { :http => 'http://dl.google.com/googleadmobadssdk/googleadmobsearchadssdkios.zip' }
        downloader = Downloader.for_target(tmp_folder_with_quotes, options)
        VCR.use_cassette('tarballs', :record => :new_episodes) { downloader.download }
        tmp_folder_with_quotes('GoogleAdMobSearchAdsSDK/GADSearchRequest.h').should.exist
        tmp_folder_with_quotes('GoogleAdMobSearchAdsSDK/GADSearchRequest.h').read.strip.should =~ /Google Search Ads iOS SDK/
      end

      it 'should flatten zip archives, when the spec explicitly demands it' do
        options = {
          :http => 'https://github.com/kevinoneill/Useful-Bits/archive/1.0.zip',
          :flatten => true
        }
        downloader = Downloader.for_target(tmp_folder, options)
        VCR.use_cassette('tarballs', :record => :new_episodes) { downloader.download }
        # Archive contains one folder, which contains 8 items. The archive is
        # 1, and the parent folder that we moved stuff out of is 1.
        Dir.glob(tmp_folder + '*').count.should == 8 + 1 + 1
      end

      # TODO: slow 90.6 s
      it 'moves unpacked contents to parent dir when archive contains only a folder (#727)' do
        downloader = Downloader.for_target(tmp_folder,
                                           :http => 'http://www.openssl.org/source/openssl-1.0.0a.tar.gz'
        )
        VCR.use_cassette('tarballs', :record => :new_episodes) { downloader.download }
        # Archive contains one folder, which contains 49 items. The archive is
        # 1, and the parent folder that we moved stuff out of is 1.
        Dir.glob(downloader.target_path + '*').count.should == 49 + 1 + 1
      end

      it 'does not move unpacked contents to parent dir when archive contains multiple children' do
        downloader = Downloader.for_target(tmp_folder,
                                           :http => 'https://testflightapp.com/media/sdk-downloads/TestFlightSDK1.0.zip'
        )
        VCR.use_cassette('tarballs', :record => :new_episodes) { downloader.download }
        # Archive contains 4 files, and the archive is 1
        Dir.glob(downloader.target_path + '*').count.should == 4 + 1
      end

      it 'raises if it fails to download' do
        options = { :http => 'broken-link.zip'  }
        downloader = Downloader.for_target(tmp_folder, options)
        lambda { downloader.download }.should.raise DownloaderError
      end

      # TODO: slow 109.7 s
      it 'should verify that the downloaded file matches a sha1 hash' do
        options = { :http => 'https://testflightapp.com/media/sdk-downloads/TestFlightSDK1.0.zip', :sha1 => 'fb62ffebfaa5b722fc50f09458aacf617a5b0177' }
        downloader = Downloader.for_target(tmp_folder, options)
        lambda { downloader.download }.should.not.raise DownloaderError
      end

      # TODO: slow 88.1 s
      it 'should fail if the sha1 hash does not match' do
        options = { :http => 'https://testflightapp.com/media/sdk-downloads/TestFlightSDK1.0.zip', :sha1 => 'invalid_sha1_hash' }
        downloader = Downloader.for_target(tmp_folder, options)
        lambda { downloader.download }.should.raise DownloaderError
      end

      it 'should verify that the downloaded file matches a sha256 hash' do
        options = { :http => 'https://testflightapp.com/media/sdk-downloads/TestFlightSDK1.0.zip', :sha256 => '400f46f915438a55166f3cea86a81c3bac33e6d76d3bfc403891434bb5518bcc' }
        downloader = Downloader.for_target(tmp_folder, options)
        lambda { downloader.download }.should.not.raise DownloaderError
      end

      it 'should fail if the sha256 hash does not match' do
        options = { :http => 'https://testflightapp.com/media/sdk-downloads/TestFlightSDK1.0.zip', :sha256 => 'invalid_sha256_hash' }
        downloader = Downloader.for_target(tmp_folder, options)
        lambda { downloader.download }.should.raise DownloaderError
      end

      #-------------------------------------------------------------------------#

      it 'detects zip files' do
        options = { :http => 'https://file.zip' }
        downloader = Downloader.for_target(tmp_folder, options)
        downloader.send(:type).should == :zip
      end

      it 'detects tar files' do
        options = { :http => 'https://file.tar' }
        downloader = Downloader.for_target(tmp_folder, options)
        downloader.send(:type).should == :tar
      end

      it 'detects tgz files' do
        options = { :http => 'https://file.tgz' }
        downloader = Downloader.for_target(tmp_folder, options)
        downloader.send(:type).should == :tgz
      end

      it 'detects tbz files' do
        options = { :http => 'https://file.tbz' }
        downloader = Downloader.for_target(tmp_folder, options)
        downloader.send(:type).should == :tbz
      end

      it 'detects txz files' do
        options = { :http => 'https://file.txz' }
        downloader = Downloader.for_target(tmp_folder, options)
        downloader.send(:type).should == :txz
      end

      it 'allows to specify the file type in the sources' do
        options = { :http => 'https://file', :type => :zip }
        downloader = Downloader.for_target(tmp_folder, options)
        downloader.send(:type).should == :zip
      end

      it 'should download file and extract it with proper type' do
        options = { :http => 'https://file.zip' }
        downloader = Downloader.for_target(tmp_folder, options)
        downloader.expects(:download_file).with(anything)
        downloader.expects(:extract_with_type).with(anything, :zip).at_least_once
        downloader.download
      end

      it 'should raise error when an unsupported file type is detected' do
        options = { :http => 'https://file.rar' }
        downloader = Downloader.for_target(tmp_folder, options)
        lambda { downloader.download }.should.raise Http::UnsupportedFileTypeError
      end

      it 'should raise error when an unsupported file type is specified in the options' do
        options = { :http => 'https://file', :type => :rar }
        downloader = Downloader.for_target(tmp_folder, options)
        lambda { downloader.download }.should.raise Http::UnsupportedFileTypeError
      end

      it 'detects the file type if specified with a string' do
        options = { :http => 'https://file', :type => 'zip' }
        downloader = Downloader.for_target(tmp_folder, options)
        downloader.send(:type).should == :zip
      end
    end
  end
end
