class CustomFieldImportController < ApplicationController

  def new
  end


  def import

  end

##
# First phase of import, only matches CSV fields to Database fields

  def match
    # params
    file = params[:file]
    splitter = params[:splitter]
    wrapper = params[:wrapper]
    encoding = params[:encoding]

    @samples = []
    @headers = []
    @attrs = []

    # save import file
    @original_filename = file.original_filename
    tmpfile = Tempfile.new("custom_value_import_import", :encoding =>'ascii-8bit')
    if tmpfile
      tmpfile.write(file.read)
      tmpfile.close
      tmpfilename = File.basename(tmpfile.path)
      if !$tmpfiles
        $tmpfiles = Hash.new
      end
      $tmpfiles[tmpfilename] = tmpfile
    else
      flash.now[:error] = l(:custom_values_cannot_save_import_file)
      return
    end

    session[:importer_tmpfile] = tmpfilename
    session[:importer_splitter] = splitter
    session[:importer_wrapper] = wrapper
    session[:importer_encoding] = encoding

    # display content
    i = 0
    quote_chars = %w(" | ~ ^ & *)
    begin
      CSV.foreach(tmpfile.path, {:headers=>true, :encoding=>encoding, :quote_char=> quote_chars.shift, :col_sep=>splitter}) do |row|
        @samples[i] = row
        i += 1
      end # do
    rescue CSV::MalformedCSVError
      quote_chars.empty? ? raise : retry
    rescue => ex
      flash.now[:error] = ex.message
    end

    if @samples.size > 0
      @headers = @samples[0].headers
    end

    # fields
    @attrs.push([t("custom_value_customized_type", default: 'customized_type'), 'customized_type'])
    @attrs.push([t("custom_value_customized_id", default: 'customized_id'), 'customized_id'])
    @attrs.push([t("custom_value_custom_field_id", default: 'custom_field_id'), 'custom_field_id'])
    @attrs.push([t("custom_value_value", default: 'value'), 'value'])
  end

##
# Performs actual creation of new CustomersController

  def result
    tmpfilename = session[:importer_tmpfile]
    splitter = session[:importer_splitter]
    wrapper = session[:importer_wrapper]
    encoding = session[:importer_encoding]

    if tmpfilename
      tmpfile = $tmpfiles[tmpfilename]
      if tmpfile == nil
        flash.now[:error] = l(:custom_values_missing_imported_file)
        return
      end
    end

    # CSV fields map
    fields_map = params[:fields_map]
    # DB attr map
    attrs_map = fields_map.invert

    @handle_count = 0
    @failed_count = 0
    @failed_rows = Hash.new
    quote_chars = %w(" | ~ ^ & *)
    begin
      CSV.foreach(tmpfile.path, {:headers=>true, :encoding=>encoding, :quote_char=> quote_chars.shift, :col_sep=>splitter}) do |row|
        custom_value = CustomValue.where(customized_id: row[attrs_map["customized_id"]], custom_field_id: row[attrs_map["custom_field_id"]], customized_type: row[attrs_map["customized_type"]]).first_or_initialize
        custom_value.value = row[attrs_map["value"]]
        if custom_value.save

        else
          flash.now[:warning] = l(:customers_message_unique_filed_duplicated)
          @failed_count += 1
          @failed_rows[@handle_count + 1] = row
        end

        @handle_count += 1
      end # do
    rescue CSV::MalformedCSVError
      quote_chars.empty? ? raise : retry
    end

    if @failed_rows.size > 0
      @failed_rows = @failed_rows.sort
      @headers = @failed_rows[0][1].headers
    else
      flash[:notice] = l(:customers_successfull_import)
    end
  end
end
