from crewai import Crew, Task, Process
from ..agents.all_agents import (
    create_head_of_ai_ml,
    create_senior_ml_engineer,
    create_ml_model_developer,
)


class MLCrew:
    
    def __init__(self):
        self.head_of_ml = create_head_of_ai_ml()
        self.senior_ml_engineer = create_senior_ml_engineer()
        self.ml_model_developer = create_ml_model_developer()
    
    def create_model_development_crew(self, model_task: str) -> Crew:
        tasks = [
            Task(
                description=f"Define ML strategy and approach for: {model_task}",
                expected_output="ML strategy document with model selection rationale",
                agent=self.head_of_ml
            ),
            Task(
                description=f"Design and train model for: {model_task}",
                expected_output="Trained model with performance metrics",
                agent=self.senior_ml_engineer
            ),
            Task(
                description=f"Optimize and deploy model for: {model_task}",
                expected_output="Optimized model ready for production deployment",
                agent=self.ml_model_developer
            ),
        ]
        
        return Crew(
            agents=[self.head_of_ml, self.senior_ml_engineer, self.ml_model_developer],
            tasks=tasks,
            process=Process.sequential,
            verbose=True
        )
