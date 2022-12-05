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
          case 'message':
            this.renderMessage(data);
            break;
          case 'typing':
            this.refreshTypingText(data);
            break;
          case 'refresh_player_roster':
            this.refreshPlayerRoster(data);
            break;
          case 'draw':
            this.draw(data);
            break;
          case 'restore_state':
            drawStateFromURL(data.url);
            break;
          case 'clear':
            this.clearCanvas();
            break;
          case 'refresh_timer':
            this.refreshTimeRemaining(data);
            break;
          case 'award_points':
            this.awardPoints(data);
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

      renderMessage(data) {
        let chat = document.querySelector('.message-container');
        let message = null;
        if (data.connection_message) {
          // connection status message
          if (data.message.endsWith('has left the chat.')) {
            document.querySelector(`.player-card[id='${data.user_id}']`).remove();
          }
          message = `
            <li>
              <p class="message">
                ${data.message}
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
        } else {
          // player guess or game start/end message
          if (data.correct_guess) {
            // document.querySelector('#chat-input').classList.add('disabled-input');
          }
          message = `
            <li>
              <p class="message">
                <b>${data.message}</b>
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

      refreshTypingText(data) {
        if (data.typing) {
          typingList.push(data.user_name);
        } else {
          typingList = typingList.filter((name) => {
            return name !== data.user_name;
          });
        }
        let text = '';
        if (typingList.length > 0) {
          text = `${typingList.join(', ')} ${typingList.length === 1 ? "is" : "are"} typing...`;
        }
        document.querySelector('.typing-message > p > i').innerText = text;
      },

      refreshPlayerRoster(data) {
        const range = document.createRange();
        let players = [];
        data.users.forEach((user, index) => {
          let playerCardHTML = `
            <li class="player-card" id="${user.id}">
              <div>
                <p class="position">${index + 1}</p>
                <p>
                  <b class="name">${user.name} <span>${((userId === user.id) ? '(you)' : '')}</span></b>
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
        });
        document.querySelector('.player-container').replaceChildren(...players);
        this.refreshGameOptionVisibility(data.drawer_id);
      },

      refreshGameOptionVisibility(id) {
        let startMatchButton = document.querySelector('#start-game');
        let drawingPalette = document.querySelector('#drawing-palette');
        if (userId === id) {
          startMatchButton.classList.remove('hidden');
          drawingPalette.classList.remove('hidden');
        } else {
          startMatchButton.classList.add('hidden');
          drawingPalette.classList.add('hidden');
        }
      },

      draw(data) {
        ctx.lineWidth = 2;
        ctx.lineCap = 'round';
        ctx.lineJoin = 'round';
        ctx.strokeStyle = `#${data.color}`;


        ctx.beginPath();
        ctx.moveTo(data.start_x, data.start_y);
        ctx.lineTo(data.end_x, data.end_y);
        ctx.stroke(); // draw it!
      },

      clearCanvas() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
      },

      refreshTimeRemaining(data) {
        gameStarted = (data.seconds !== 60);
        document.querySelector('#time-remaining').innerText = `${data.seconds}s`;
      }
    });

    /* Utilities */
    let gameStarted = false;
    const userId = parseInt(document.querySelector('.player-container').id);
    const getNameFromId = (id) => {
      return document
        .querySelector(`.player-card[id='${id}'] > div > p > b`)
        .innerHTML.replace(/ <span>.*<\/span>/g, '');
    };

    /* Palette */
    const clearButton = document.querySelector('.palette-element__clear-button');
    const paintColorOptions = document.querySelectorAll('.palette-element__color');
    let selectedColorOption = paintColorOptions[0];
    selectedColorOption.classList.toggle('palette-element--selected');

    const getSelectedColor = () => {
      return selectedColorOption ? selectedColorOption.id : 'black';
    };

    paintColorOptions.forEach((element) => {
      element.addEventListener('click', (event) => {
        selectedColorOption.classList.toggle('palette-element--selected');
        selectedColorOption = event.target;
        selectedColorOption.classList.toggle('palette-element--selected');
      })
    });
    clearButton.addEventListener('click', () => {
      redoData = [];
      undoData = [];
      toggleUndoVisibility();

      channel.emit({ context: 'clear' })
    });

    /* Drawing */
    let canvas = document.querySelector('canvas');
    let offset = canvas.getBoundingClientRect();
    let ctx = canvas.getContext('2d');
    let isDrawing = false;
    let p1 = { x: 0, y: 0 }
    let p2 = { x: 0, y: 0 }

    // used for undo/redo functionality
    let captureCanvasState = false;

    // Scales point coordinates so that it's relative to canvas element.
    // 'point' argument is modified.
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

    let undoButton = document.querySelector('.palette-element__undo-button');
    let redoButton = document.querySelector('.palette-element__redo-button');
    let undoData = []; // used as a stack.
    let redoData = []; // used as a queue.

    const saveState = (event) => {
      redoData = [];
      undoData.push(canvas.toDataURL());
      toggleUndoVisibility();
    };

    // pre: undoData.length >= 1
    const undoState = () => {
      redoData.unshift(undoData.pop());
      channel.emit({ context: 'clear' });
      if (undoData.length > 0) {
        channel.emit({ context: 'restore_state', url: undoData[undoData.length - 1] })
      }
      toggleUndoVisibility();
    };

    // pre: redoData.length >= 1
    const redoState = () => {
      const dataURL = redoData.shift();
      undoData.push(dataURL);
      channel.emit({ context: 'clear' });
      channel.emit({ context: 'restore_state', url: dataURL })
      toggleUndoVisibility();
    };

    const drawStateFromURL = (url) => {
      let img = document.createElement('img');
      img.src = url;
      img.addEventListener('load', () => {
        ctx.drawImage(img, 0, 0);
      });
    };

    const toggleUndoVisibility = () => {
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


    window.addEventListener("resize", () => {
      offset = canvas.getBoundingClientRect();
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
    canvas.addEventListener('mousedown', (event) => {
      isDrawing = true;
      offset = canvas.getBoundingClientRect();
      scalePoint(p1, event);
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

    /* Messaging */
    const chatInput = document.querySelector('input#chat_input');
    let typingList = [];
    let isTyping = false;

    chatInput.addEventListener('keydown', (event) => {
      if (!isTyping) {
        isTyping = true;
        channel.emit({
          context: 'typing',
          user_name: getNameFromId(userId),
          typing: isTyping
        });
        setTimeout(() => {
          isTyping = false;
          channel.emit({
            context: 'typing',
            user_name: getNameFromId(userId),
            typing: isTyping
          });
        }, 1000);
      }

      if (event.code === 'Enter') {
        const sanitizedInput = event.target.value.replace(/<(.|\n)*?>/g, '');
        event.preventDefault();
        if (sanitizedInput.length > 0) {
          // If the drawing palette is visible, it means that it's our turn to draw.
          // Therefore, anything we type in the chat should NOT be counted as a guess.
          const isDrawing = !document.querySelector('#drawing-palette').classList.contains('hidden');
          isTyping = false;
          channel.emit({
            context: 'typing',
            user_name: getNameFromId(userId),
            typing: isTyping
          });
          channel.emit({
            context: 'message',
            user_id: userId,
            user_name: getNameFromId(userId),
            message: sanitizedInput,
            is_guess: (gameStarted && !isDrawing),
            point_award: getSecondsRemaining(),
          });
          event.target.value = '';
        }
      }
    });

    /* Turn based mechanics */
    const wordOptionOverlay = document.querySelector('.u-overlay-container');
    const wordOptions = document.querySelectorAll('.c-card.c-card__word');
    const getSecondsRemaining = () => {
      return parseInt(document.querySelector('#time-remaining').innerText);
    };
    const handleWordSelection = (event) => {
      channel.emit({
        context: 'message',
        message: `${getNameFromId(userId)} is now drawing.`,
      });

      wordOptionOverlay.classList.add('hidden');
      document.querySelector('#start-game').classList.add('hidden');

      const word = event.target.querySelector('p.title').innerText;
      channel.emit({ context: 'start', word: word });

      console.log('start');
      gameStarted = true;
      const interval = setInterval(() => {
        // This is being placed in the interval so that it will set correctly if
        // the user currently drawing refreshes their tab.
        gameStarted = true;
        console.log('tic');
        let seconds = getSecondsRemaining();
        if (seconds === 0) {
          gameStarted = false;
          console.log('stop');
          window.clearInterval(interval);
          channel.emit({ context: 'stop' })
        } else {
          channel.emit({ context: 'refresh_timer', seconds: (seconds - 1) })
        }
      }, 1000);
    };

    wordOptions.forEach((element) => {
      element.addEventListener('click', handleWordSelection);
    });
    document.querySelector('#start-game').addEventListener('click', (event) => {
      event.preventDefault();
      wordOptionOverlay.classList.remove('hidden');
      channel.emit({
        context: 'message',
        message: `${getNameFromId(userId)} is choosing a word.`,
      });
    });
  }
})();
