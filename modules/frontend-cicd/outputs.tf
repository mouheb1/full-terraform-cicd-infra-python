output "codepipeline_name" {
  description = "Name of the CodePipeline for the React app"
  value       = aws_codepipeline.frontend.name
}

output "codepipeline_arn" {
  description = "ARN of the CodePipeline for the React app"
  value       = aws_codepipeline.frontend.arn
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project for the React app"
  value       = aws_codebuild_project.frontend.name
}

output "codebuild_project_arn" {
  description = "ARN of the CodeBuild project for the React app"
  value       = aws_codebuild_project.frontend.arn
}