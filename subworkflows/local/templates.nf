include { CREATE_TCOFFEETEMPLATE } from '../../modules/local/create_tcoffee_template'

workflow TEMPLATES {

    take:
    ch_dependencies // channel: [ meta, /path/to/file.* ]
    ch_templates // channel: [ meta, /path/to/template.txt ]
    suffix

    main:

    ch_versions     = Channel.empty()

    ch_dependencies_template = ch_dependencies.join(ch_templates, by:0, remainder:true)
    ch_dependencies_template
        .branch {
            template: it[2] != null
            no_template: true
        }
        .set { ch_dependencies_branched }

    // Create the new templates and merge them with the existing templates
    CREATE_TCOFFEETEMPLATE (
        ch_dependencies_branched.no_template
            .map {
                meta,dependencies,template ->
                    [ meta, suffix, dependencies ]
            }
    )
    new_templates = CREATE_TCOFFEETEMPLATE.out.template
    ch_versions = CREATE_TCOFFEETEMPLATE.out.versions

    ch_dependencies_branched.template
        .map {
            meta,dependencies,template ->
                [ meta, template ]
        }
        .set { forced_templates }

    ch_templates_merged = forced_templates.mix(new_templates)

    // Merge the dependencies and templates channels, ready for the alignment
    ch_dependencies_template = ch_templates_merged.combine(ch_dependencies, by:0)

    emit:
    dependencies_template =  ch_dependencies_template
    versions = ch_versions

}
