import consumer from "channels/consumer"

(() => {
  const split = window.location.pathname.split('/');
  if (split[1] === 'staging_areas' && typeof split[2] === 'string') {
    const slug = split[2];
    const channel = consumer.subscriptions.create({ channel: 'StagingAreaChannel', slug: slug }, {
      // Called when the subscription is ready for use on the server
      connected() {
        console.log('connected to staging area channel!');
      },

      // Called when the subscription has been terminated by the server
      disconnected() {
        console.log('disconnected from staging area channel!');
      },

      // Called when there's incoming data on the websocket for this channel
      received(data) {
        console.log('data receieved', data);
        const range = document.createRange();
        let players = [];
        document.querySelector('h3').innerText = `Players in room '${data.slug}' (${data.users.length})`
        if (data.users.length > 0) {
          document.querySelector('#room-information').classList.remove('hidden');
          data.users.forEach((user) => {
            let playerCardHTML = `
              <div class="c-card animate-pop-in">
                <p class="title">${user.name}</p>
              </div>
            `;
            const playerCard = range.createContextualFragment(playerCardHTML);
            players.push(playerCard);
          });
          document.querySelector('.player-staging-container').replaceChildren(...players);
        } else {
          document.querySelector('#room-information').classList.add('hidden');
        }
      },
    });

    const nameInput = document.querySelector('#name_input');
    const submitButton = document.querySelector('form > button');

    const names = () => {
      return Array.from(
        document.querySelectorAll('.c-card > .title')
      ).map((node) => { return node.innerText; });
    }

    const shake = () => {
      const form = document.querySelector('form');

      form.classList.add('invalid-input');
      setTimeout(() => {
        form.classList.remove('invalid-input');
      }, 500);
    }

    const setNameRequest = (name) => {
      name = name.trim();
      if (names().includes(name)) {
        document.querySelector('p.error').innerText = `'${name}' is already taken, please enter another.`;
        shake();
        return;
      }
      // Calls 'StagingAreaChannel#set_name(data)' on the server.
      channel.perform('set_name', { name: name });
      // For whatever reason, on Firefox the re-direct would occur before the
      // logic in StagingAreaChannel#set_name(data) completed. This would yield
      // in the user joining a room with a name of 'nil'. To remedy this, I
      // added a slight re-direct delay.
      setTimeout(() => {
        // Now that our name is set, let's hop into the game room! :)
        window.location.href = `/rooms/${slug}`;
      }, 10);
    };

    submitButton.addEventListener('click', (event) => {
      event.preventDefault();
      if (nameInput.value.length > 0) {
        setNameRequest(nameInput.value);
      }
    });
    nameInput.addEventListener('keydown', (event) => {
      if (event.code === 'Enter') {
        const sanitizedInput = event.target.value.replace(/<(.|\n)*?>/g, '');
        event.preventDefault();
        if (sanitizedInput.length > 0) {
          setNameRequest(sanitizedInput);
        }
      }
    })
  }
})();
