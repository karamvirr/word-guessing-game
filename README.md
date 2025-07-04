# Word Guessing Game 🎨

A real-time multiplayer drawing and guessing game built with Ruby on Rails and WebSockets. Players take turns drawing words while others guess, featuring live canvas synchronization and interactive gameplay.

## 📸 Screenshots
<div align="center">
   <img src="https://github.com/user-attachments/assets/98f173da-3bd6-467b-9287-6765ce66c82a" alt="Home Page" width="80%" />
   <img src="https://github.com/user-attachments/assets/451272c0-9ed2-4845-bfd4-224354104eae" alt="Game Room Screenshot #1" width="80%" />
   <img src="https://github.com/user-attachments/assets/9eb28790-a820-406a-b2ca-5b9461f06114" alt="Game Room Screenshot #2" width="80%" />
   <img src="https://github.com/user-attachments/assets/5b82e56f-74ce-4d77-948c-6018afea4171" alt="Game Room Screenshot #3" width="80%" />
   <img src="https://github.com/user-attachments/assets/6aa165bc-aad1-4726-b0ec-cd36596963c3" alt="Game Room Screenshot #4" width="80%" />
   <img src="https://github.com/user-attachments/assets/3aba11f7-f0af-49b1-8979-c89ea8f6db56" alt="Game Room Screenshot #5" width="80%" />
   <img src="https://github.com/user-attachments/assets/60a5812d-dd14-43df-84b8-301c2839c1a8" alt="Game Room Screenshot #6" width="80%" />
   <img src="https://github.com/user-attachments/assets/c6806038-5503-40d4-bd9b-d0198108a856" alt="Game Room Screenshot #7" width="80%" />
</div>

## 🎮 Game Features

- **Real-time Multiplayer**: Up to multiple players per room with live synchronization
- **Drawing Tools**: Complete drawing palette with colors, brush sizes, and flood fill
- **Smart Guessing**: Partial letter hints revealed for close guesses
- **Scoring System**: Points awarded based on guess speed (time remaining)
- **Round-based Play**: 3 rounds with rotating drawers
- **Word Difficulties**: Easy, Medium, and Hard word options
- **Mobile Support**: Touch-friendly interface for mobile devices

## 🛠️ Technical Stack

- **Backend**: Ruby on Rails 7.0.4
- **Database**: PostgreSQL
- **Real-time**: ActionCable (WebSockets)
- **Frontend**: Turbo, Stimulus, Slim templates
- **Styling**: Sass with responsive design
- **Testing**: RSpec with FactoryBot

## 🎯 How to Play

1. **Create/Join Room**: Create a new room or join with a room code
2. **Set Username**: Enter your name in the staging area
3. **Start Game**: Begin when all players are ready
4. **Draw & Guess**:
   - Drawer selects a word and draws it (90 seconds)
   - Other players guess in the chat
   - Points awarded for correct guesses
5. **Rotate Turns**: Each player gets to draw over 3 rounds
6. **Final Scores**: Winner determined by total points

## 🎨 Drawing Tools

- **Color Palette**: 10 colors (black, red, orange, yellow, green, blue, purple, brown, silver, white)
- **Brush Sizes**: Adjustable from 1-50px
- **Flood Fill**: Paint bucket tool for filling areas
- **Clear Canvas**: Reset the drawing
- **Undo/Redo**: Drawing history management

## 🪣 [Flood Fill Algorithm](https://en.wikipedia.org/wiki/Flood_fill)

The flood fill (paint bucket) tool allows users to quickly fill large areas with color by clicking on any region of the canvas.

<div align="center">
  <img src="https://github.com/user-attachments/assets/5f25882d-b922-43ed-aca5-53bd470c41a5" alt="Flood Fill Demo">
  <p><em>Flood fill algorithm demonstration (slowed down to visualize the pixel-by-pixel traversal)</em></p>
</div>

The implementation uses a **stack-based flood fill algorithm** that efficiently fills connected regions of the same color. Starting from the clicked pixel, the algorithm uses a **stack data structure** to track neighboring pixels and performs **4-connected traversal** (up, down, left, right) to identify all pixels that should be filled. The algorithm includes **boundary checking** to prevent overflow and **safety limits** to handle large areas gracefully. All flood fill operations are synchronized in **real-time** across connected players via WebSockets, ensuring everyone sees the same canvas state instantly.

## 📋 Requirements

- Ruby 3.4.1
- PostgreSQL
- Redis (for ActionCable)
- Node.js (for asset compilation)

## 🚀 Getting Started

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd word-guessing-game

# Install dependencies
bundle install

# Setup database
rails db:create
rails db:migrate
rails db:seed

# Start Redis (required for ActionCable)
redis-server

# Start the server
rails server

# Visit the application
open https://localhost:3000
```

### Environment Setup

Create a `.env` file in the root directory:

```env
# Database configuration (if needed)
DATABASE_URL=postgresql://localhost/word_guessing_game_development

# Redis configuration (if needed)
REDIS_URL=redis://localhost:6379
```

### Database Configuration

The application uses PostgreSQL with the following databases:
- Development: `word_guessing_game_development`
- Test: `word_guessing_game_test`
- Production: `word_guessing_game_production`

## 🧪 Testing

Run the test suite:

```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/models/room_spec.rb
bundle exec rspec spec/channels/room_channel_spec.rb

# Run with coverage
bundle exec rspec --format documentation
```

## 🏗️ Architecture

### Models

- **Room**: Game sessions with unique slugs, manages game state and scoring
- **User**: Players with scores, belongs to rooms, auto-cleanup on disconnect
- **Word**: Dictionary with difficulty levels (Easy/Medium/Hard)

### Real-time Features

- **ActionCable Channels**:
  - `RoomChannel`: Game state, drawing, and chat
  - `StagingAreaChannel`: Pre-game lobby
- **WebSocket Events**: Drawing synchronization, game state updates, chat messages

### Key Components

- **Game Logic**: Turn rotation, scoring, time management
- **Drawing Engine**: Canvas manipulation, flood fill algorithm
- **Chat System**: Real-time messaging with guess validation
- **Room Management**: User connections, disconnection handling

## 🔧 Configuration

### Production Setup

Set the following environment variables:

```bash
WORD_GUESSING_GAME_DATABASE_PASSWORD=your_db_password
RAILS_ENV=production
SECRET_KEY_BASE=your_secret_key
```

### ActionCable Configuration

Configure `config/cable.yml` for production:

```yaml
production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
  channel_prefix: word_guessing_game_production
```

## 📱 Mobile Support

The game is fully responsive and supports:
- Touch drawing on mobile devices
- Responsive UI that adapts to screen size
- Touch-friendly controls and buttons
- Mobile-optimized chat interface

## 🎯 Game Rules

- **Time Limit**: 90 seconds per turn
- **Rounds**: 3 rounds total
- **Scoring**: Points = time remaining when guessed correctly
- **Hints**: Letters revealed for close guesses
- **Turn End**: When time expires or everyone guesses correctly

## 🔄 Real-time Synchronization

All game actions are synchronized in real-time:
- Drawing strokes and flood fills
- Chat messages and guesses
- Game state changes (start/end turns)
- Player connections and disconnections
- Score updates and hints

## 🚀 Deployment

The application is ready for deployment on platforms like:
- Heroku
- Railway
- Render
- Any platform supporting Rails + PostgreSQL + Redis

## 📄 License

This project is available as open source under the terms of the MIT License.
