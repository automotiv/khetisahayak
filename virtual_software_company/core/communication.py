from typing import Dict, List
from agents.base_agent import BaseAgent, Message

class CommunicationBus:
    def __init__(self):
        self.agents: Dict[str, BaseAgent] = {}
        self.role_map: Dict[str, BaseAgent] = {} # Map role to agent instance

    def register_agent(self, agent: BaseAgent):
        self.agents[agent.id] = agent
        self.role_map[agent.role] = agent
        print(f"Registered Agent: {agent.role}")

    def route_message(self, message: Message):
        """
        Routes a message to the intended recipient.
        """
        # Find recipient by role
        # In a real system with multiple people in same role, we'd need better addressing (e.g. by ID or "All Backend Devs")
        # For this MVP, we will assume roles are unique keys OR handle partial matches
        
        target = self.role_map.get(message.receiver_role)
        
        # If exact role match fails, try to find by broad category if needed, 
        # but for now let's assume specific targeting or handle lists.
        
        # Improvement: Handle multiple agents with same role (e.g. "Backend Dev 1")
        if target:
            target.receive_message(message)
        else:
            # Try finding if it was a specific name or ID
            pass
            print(f"Error: Could not find recipient role '{message.receiver_role}'")

    def broadcast(self, sender: BaseAgent, content: str):
        for agent_id, agent in self.agents.items():
            if agent_id != sender.id:
                msg = Message(
                    sender_id=sender.id,
                    sender_role=sender.role,
                    receiver_role=agent.role,
                    content=content,
                    message_type="BROADCAST"
                )
                agent.receive_message(msg)
