include { CREATE_TCOFFEETEMPLATE } from '../../modules/local/create_tcoffee_template'

workflow TEMPLATES {

    take:
    ch_optional_data // channel: [ meta, /path/to/file.* ]
    ch_templates // channel: [ meta, /path/to/template.txt ]
    suffix

    main:

    ch_versions     = Channel.empty()

    ch_optional_data_template = ch_optional_data.join(ch_templates, by:0, remainder:true)
    ch_optional_data_template
        .branch {
            template: it[2] != null
            no_template: true
        }
        .set { ch_optional_data_branched }

    // Create the new templates and merge them with the existing templates
    CREATE_TCOFFEETEMPLATE (
        ch_optional_data_branched.no_template
            .map {
                meta,optional_data,template ->
                    [ meta, suffix, optional_data ]
            }
    )
    new_templates = CREATE_TCOFFEETEMPLATE.out.template
    ch_versions = CREATE_TCOFFEETEMPLATE.out.versions

    ch_optional_data_branched.template
        .map {
            meta,optional_data,template ->
                [ meta, template ]
        }
        .set { forced_templates }

    ch_templates_merged = forced_templates.mix(new_templates)

    // Merge the optional_data and templates channels, ready for the alignment
    ch_optional_data_template = ch_templates_merged.combine(ch_optional_data, by:0)
    ch_optional_data_template.view()

    emit:
    optional_data_template =  ch_optional_data_template
    versions = ch_versions

}
