import consumer from "channels/consumer"

(() => {
  const split = window.location.pathname.split('/');
  if (split[1] === 'rooms' && typeof split[2] === 'string') {
    const slug = split[2];
    const channel = consumer.subscriptions.create({ channel: 'RoomChannel', slug: slug }, {
      // Called when the subscription is ready for user on the server.
      connected() {
        console.log('welcome to the party!');
      },

      // Called when the subscription has been terminated by the server.
      disconnected() {
        console.log('thanks for coming!');
      },

      // Called when there's incoming data on the websocket for this channel
      received(data) {
        switch (data.context) {
          case 'draw':
            this.draw(data);
            break;
          case 'clear_canvas':
            this.clearCanvas();
            break;
          case 'restore_state':
            this.drawStateFromURL(data.url);
            break;
          case 'message':
            this.renderMessage(data);
            break;
          case 'typing':
            this.refreshTypingText(data);
            break;
          case 'refresh_components':
            this.refreshComponents(data);
            break;
          case 'refresh_time_remaining_header':
            this.refreshTimeRemaining(data.seconds);
            break;
          case 'hide_overlay':
            this.hideOverlay();
            break;
          case 'word_options':
            this.renderWordOptions(data);
            break;
          case 'scoreboard':
            this.renderScoreboard(data);
            break;
          case 'set_header':
            this.refreshHeader(data);
            break;
          case 'start_timer':
            startTimer();
            break;
          case 'stop_timer':
            stopTimer();
            break;
        }
      },

      // Broadcasts the hash provided as a parameter to all subscribers/consumers
      // of the current channel.
      //
      // @param {JSON} data - payload to be sent over to the server.
      emit(data) {
        // Calls 'RoomChannel#received(data)' on the server.
        channel.perform('received', data);
      },

      // @param {JSON} data - payload containing data to draw data. more
      //                      specifically, it contains information such as
      //                      line color, and starting and endpoint points of
      //                      the path to draw.
      draw(data) {
        ctx.lineWidth = 5;
        ctx.lineCap = 'round';
        ctx.lineJoin = 'round';
        ctx.strokeStyle = `#${data.color}`;


        ctx.beginPath();
        ctx.moveTo(data.start_x, data.start_y);
        ctx.lineTo(data.end_x, data.end_y);
        ctx.stroke(); // draw it!
      },

      // removes all drawings from the canvas.
      clearCanvas() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
      },

      // removes any overlay on top of canvas from view.
      hideOverlay() {
        document.querySelector('.u-overlay').classList.add('hidden');
      },

      // @param {String} url - contains a representation of a canvas snapshot
      //                       in the img/png format.
      drawStateFromURL(url) {
        let img = document.createElement('img');
        img.src = url;
        img.addEventListener('load', () => {
          ctx.drawImage(img, 0, 0);
        });
      },

      // @param {JSON} data - payload containing message content.
      renderMessage(data) {
        let chat = document.querySelector('.message-container');
        let message = null;
        if (data.server_message) {
          if (data.message.endsWith('has left the chat.')) {
            document.querySelector(`.player-card[id='${data.user_id}']`).remove();
          }
          message = `
            <li>
              <p class="message" ${true ? `style="color: ${data.color_hex}"` : ""}>
                <b>${data.message}</b>
              </p>
            </li>
          `;
        } else if (data.user_name) {
          // player message
          message = `
            <li>
              <p class="message">
                <b>${data.user_name}:</b>
                <span>&nbsp;${data.message}</span>
              </p>
            </li>
          `;
        }
        chat.insertAdjacentHTML("beforeend", message);
        chat.scrollTo({
          top: chat.scrollHeight,
          left: 0,
          behavior: 'smooth'
        });
      },

      // @param {JSON} data - payload containing information about a user in
      //                     the room and whether or not they are currently typing,
      refreshTypingText(data) {
        if (data.typing) {
          usersTyping.push(data.user_name);
        } else {
          usersTyping = usersTyping.filter((name) => {
            return name !== data.user_name;
          });
        }
        let text = '';
        if (usersTyping.length > 0) {
          text = `${usersTyping.join(', ')} ${usersTyping.length === 1 ? "is" : "are"} typing...`;
        }
        document.querySelector('.typing-message > p > i').innerText = text;
      },

      // @param {JSON} data - payload containing player data such as name,
      //                      score, and whether or not they are drawing.
      refreshComponents(data) {
        const range = document.createRange();
        let players = [];
        data.users.forEach((user, index) => {
          let playerCardHTML = `
            <li class="player-card" id="${user.id}"
              ${(user.guessed_correctly) ? `style="background: #79eb79"` : ""}>
              <div>
                <p class="position">${index + 1}</p>
                <p>
                  <b class="name">
                    ${user.name}
                    <span>${((userId === user.id) ? '(you)' : '')}</span>
                  </b>
                  <br>
                  <span class="score">${user.score} PTS</span>
                </p>
              </div>
              ${(user.id === data.drawer_id) ?
                `<i class="fa fa-pencil"></i>` : ""}
            </li>
          `;
          const playerCard = range.createContextualFragment(playerCardHTML);
          players.push(playerCard);
          if (user.id === userId) {
            this.toggleChatDisabled(user.guessed_correctly);
          }
        });
        document.querySelector('.player-container').replaceChildren(...players);

        this.updateDisplayedRoundNumberText(data.round);
        this.toggleStartGameButtonVisibility(data.game_started, data.drawer_id);
        this.toggleDrawingPaletteVisibility(data.drawer_id);
      },

      // @param {Integer} seconds - time remaining for current drawer's turn.
      refreshTimeRemaining(seconds) {
        document.querySelector('#time-remaining').innerText = `${seconds}s`;
      },

      // @param {Boolean} gameStarted - indicates whether or not the game has
      //                                started. payload containing player data such as name,
      // @param {Integer} id          - user id of current drawer.
      toggleStartGameButtonVisibility(gameStarted, id) {
        let startButton = document.querySelector('#start-game');
        if (!gameStarted && (id == userId)) {
          startButton.classList.remove('hidden');
        } else {
          startButton.classList.add('hidden');
        }
      },

      // @param {Integer} drawerId - user id of the current drawer.
      toggleDrawingPaletteVisibility(drawerId) {
        if (drawerId == userId) {
          document.querySelector('#drawing-palette').classList.remove('hidden');
        } else {
          document.querySelector('#drawing-palette').classList.add('hidden');
        }
      },

      // @param {Boolean} disable - boolean used to determine whether or not
      //                            to disable chat input for the current user.
      toggleChatDisabled(disable) {
        chatInput.disabled = disable;
      },

      // @param {Integer} round - current round of the game.
      updateDisplayedRoundNumberText(data) {
        const text = `Round ${data} of 3`;
        document.querySelector('#round-information').innerText = text;
      },

      // @param {JSON} data - payload containing word data.
      renderWordOptions(data) {
        undoData = [];
        redoData = [];
        toggleUndoRedoVisibility();
        const overlay = document.querySelector('.u-overlay');
        const range = document.createRange();
        let header = document.querySelector('.u-overlay h2');
        let words = [];
        data.words.forEach((word) => {
          const wordCardHTML = `
            <div class="c-card c-card__word animate-pop-in">
              <p class="title">${word[0]}</p>
              <p class="subtitle">${word[1]}</p>
            </div>
          `;
          const wordCard = range.createContextualFragment(wordCardHTML);
          words.push(wordCard);
        })
        overlay.classList.remove('hidden');
        header.innerText = 'Please choose a word!';
        document.querySelector('.u-card-container').replaceChildren(...words);

        let counter = 25;
        const wordSelectionTimer = setInterval(() => {
          if (counter <= 10) {
            header.innerText = `Please choose a word in ${counter}s!`;
          }
          if (counter === 0) {
            clearInterval(wordSelectionTimer);
            overlay.classList.add('hidden');
            channel.emit({ context: 'end_turn' });
          }
          counter -= 1;
        }, 1000);

        document.querySelectorAll('.c-card__word').forEach((element) => {
          element.addEventListener('click', (event) => {
            clearInterval(wordSelectionTimer);
            overlay.classList.add('hidden');
            channel.emit({
              context: 'start_turn',
              word: event.target.querySelector('p.title').innerText
            });
          });
        });
      },

      // @param {JSON} data - payload containing scoreboard data.
      renderScoreboard(data) {
        const overlay = document.querySelector('.u-overlay');
        const range = document.createRange();
        let header = document.querySelector('.u-overlay h2');
        let users = [];
        data.users.forEach((user) => {
          const userCardHTML = `
            <div class="c-card animate-pop-in">
              <p class="title">${user.name}</p>
              <p class="subtitle">${user.score} PTS</p>
            </div>
          `;
          const userCard = range.createContextualFragment(userCardHTML);
          users.push(userCard);
        })
        overlay.classList.remove('hidden');
        header.innerText = 'Thanks for playing!';
        document.querySelector('.u-card-container').replaceChildren(...users);
      },

      // @param {JSON} data - payload containing header text information.
      refreshHeader(data) {
        const text = (data.drawer_id == userId) ? data.word : data.hint;
        document.querySelector('h2#word').innerText = text;
      }
    });

    /* Utilities */
    const username = document.querySelector('tr.second-row > td').id;
    const userId = parseInt(document.querySelector('.player-container').id);

    /* Messaging */
    const chatInput = document.querySelector('input#chat_input');
    let usersTyping = [];
    let isTyping = false;
    const emitTypingEvent = () => {
      channel.emit({
        context: 'typing',
        user_name: username,
        typing: isTyping
      });
    };

    chatInput.addEventListener('keydown', (event) => {
      if (!(event.code.includes('Arrow') || isTyping)) {
        isTyping = true;
        emitTypingEvent();
        setTimeout(() => {
          isTyping = false;
          emitTypingEvent();
        }, 1000);
      }
      if (event.code === 'Enter') {
        event.preventDefault();
        const sanitizedInput = event.target.value.replace(/<(.|\n)*?>/g, '');
        if (sanitizedInput.length > 0) {
          channel.emit({
            context: 'message',
            user_id: userId,
            user_name: username,
            message: sanitizedInput
          });
          event.target.value = '';
        }
      }
    });

    /* Game mechanics */
    const startGameButton = document.querySelector('#start-game');
    startGameButton.addEventListener('click', (event) => {
      event.preventDefault();
      startGameButton.classList.add('hidden');
      channel.emit({ context: 'start_game' });
    });

    let turnTimer = null;
    const startTimer = () => {
      if (turnTimer === null) {
        turnTimer = setInterval(() => {
          channel.emit({ context: 'decrement_time_remaining' });
        }, 1000);
      }
    };
    const stopTimer = () => {
      clearInterval(turnTimer);
      turnTimer = null;
    };

    /* Undo/Redo/Clear Drawing Buttons */
    const clearButton = document.querySelector('.palette-element__clear-button');
    let undoButton = document.querySelector('.palette-element__undo-button');
    let redoButton = document.querySelector('.palette-element__redo-button');
    let undoData = []; // used as a stack.
    let redoData = []; // used as a queue.

    clearButton.addEventListener('click', () => {
      redoData = [];
      undoData = [];
      toggleUndoRedoVisibility();

      channel.emit({ context: 'clear_canvas' });
    });

    const saveState = () => {
      redoData = [];
      undoData.push(canvas.toDataURL());
      toggleUndoRedoVisibility();
    };

    // pre: undoData.length >= 1
    const undoState = () => {
      redoData.unshift(undoData.pop());
      channel.emit({ context: 'clear_canvas' });
      if (undoData.length > 0) {
        channel.emit({ context: 'restore_state', url: undoData[undoData.length - 1] })
      }
      toggleUndoRedoVisibility();
    };

    // pre: redoData.length >= 1
    const redoState = () => {
      const dataURL = redoData.shift();
      undoData.push(dataURL);
      channel.emit({ context: 'clear_canvas' });
      channel.emit({ context: 'restore_state', url: dataURL })
      toggleUndoRedoVisibility();
    };

    const toggleUndoRedoVisibility = () => {
      if (undoData.length == 0) {
        undoButton.classList.add('palette-element-hidden');
      } else {
        undoButton.classList.remove('palette-element-hidden');
      }
      if (redoData.length == 0) {
        redoButton.classList.add('palette-element-hidden');
      } else {
        redoButton.classList.remove('palette-element-hidden');
      }
    };

    undoButton.addEventListener('click', undoState);
    redoButton.addEventListener('click', redoState);

    /* Color Palette */
    const paintColorOptions = document.querySelectorAll('.palette-element__color');
    let selectedColorOption = paintColorOptions[0];
    selectedColorOption.classList.toggle('palette-element--selected');

    const getSelectedColor = () => {
      return selectedColorOption ? selectedColorOption.id : '#000000';
    };

    paintColorOptions.forEach((element) => {
      element.addEventListener('click', (event) => {
        selectedColorOption.classList.toggle('palette-element--selected');
        selectedColorOption = event.target;
        selectedColorOption.classList.toggle('palette-element--selected');
      })
    });

    /* Drawing */
    let canvas = document.querySelector('canvas');
    canvas.width = canvas.clientWidth;
    canvas.height = canvas.clientHeight;
    let offset = canvas.getBoundingClientRect();
    let ctx = canvas.getContext('2d');
    let isDrawing = false;
    let p1 = { x: 0, y: 0 }
    let p2 = { x: 0, y: 0 }

    // used for undo/redo functionality
    let captureCanvasState = false;

    // scales point coordinates so that it's relative to canvas element.
    // note: 'point' argument is modified during execution.
    const scalePoint = (point, event) => {
      const scaleX = canvas.width / offset.width;
      const scaleY = canvas.height / offset.height;

      point.x = (event.clientX - offset.left) * scaleX;
      point.y = (event.clientY - offset.top) * scaleY;
    };

    // Returns distance between points a and b
    // pre: arguments are objects with x, y values.
    const pointDistance = (a, b) => {
      return Math.sqrt(Math.pow(b.x - a.x, 2) + Math.pow(b.y - a.y, 2));
    };

    window.addEventListener("resize", () => {
      offset = canvas.getBoundingClientRect();
    });

    canvas.addEventListener('mousedown', (event) => {
      isDrawing = true;
      offset = canvas.getBoundingClientRect();
      scalePoint(p1, event);
    });
    canvas.addEventListener('mouseleave', () => {
      isDrawing = false;
    });
    canvas.addEventListener('mouseup', () => {
      isDrawing = false;
      if (captureCanvasState) {
        saveState();
      }
      captureCanvasState = false;
    });
    canvas.addEventListener('mousemove', (event) => {
      if (isDrawing) {
        scalePoint(p2, event);
        if(pointDistance(p1, p2) > 2) {
          captureCanvasState = true;
          channel.emit({
            context: 'draw',
            color: getSelectedColor(),
            start_x: p1.x,
            start_y: p1.y,
            end_x: p2.x,
            end_y: p2.y
          })
          p1.x = p2.x;
          p1.y = p2.y;
        }
      }
    });
  }
})();
