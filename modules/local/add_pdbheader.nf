process ADD_PDBHEADER{
  container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
      'https://depot.galaxyproject.org/singularity/mulled-v2-a76a981c07359a31ff55b9dc13bd3da5ce1909c1:84c8f17f1259b49e2f7783b95b7a89c6f2cb199e-0':
      'biocontainers/mulled-v2-a76a981c07359a31ff55b9dc13bd3da5ce1909c1:84c8f17f1259b49e2f7783b95b7a89c6f2cb199e-0' }"

  label "process_low"

  input:
  tuple val(meta), path(pdb)

  output:
  tuple val(meta), path("${pdb.baseName}.pdb"), emit: pdb

  script:
  """
  export TEMP='./'
  # Add the headers
  mkdir pdbs_unprocessed
  mv $pdb pdbs_unprocessed
  t_coffee -other_pg extract_from_pdb -infile pdbs_unprocessed/$pdb > ${pdb.baseName}.pdb
  """
}