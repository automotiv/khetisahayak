# ---- Base Stage ----
# Use an official Node.js runtime as a parent image.
# Using alpine for a smaller and more secure image.
FROM node:18-alpine AS base

# Create and set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json to leverage Docker cache
COPY package*.json ./


# ---- Builder Stage ----
# This stage installs all dependencies, including devDependencies,
# which might be needed for a build or test step in the future.
FROM base AS builder
RUN npm install


# ---- Production Stage ----
# This stage creates the final, lean production image.
FROM base AS production

# Copy only the production node_modules from the builder stage
COPY --from=builder /usr/src/app/node_modules ./node_modules

# Copy the rest of the application source code
COPY . .

# Copy and set permissions for the entrypoint script
COPY ./entrypoint.sh /usr/src/app/entrypoint.sh
RUN chmod +x /usr/src/app/entrypoint.sh

# Your app binds to port 3000, so you'll need to expose it
EXPOSE 3000

# Set the entrypoint script to run on container start
ENTRYPOINT ["/usr/src/app/entrypoint.sh"]
# Define the default command to be executed by the entrypoint script
CMD [ "npm", "start" ]